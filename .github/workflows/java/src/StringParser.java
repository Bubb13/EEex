
import java.util.Stack;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class StringParser
{
	private final String string;
	private int curPos = 0;

	private final Stack<Integer> posStack = new Stack<>();
	private final Stack<Integer> captureStack = new Stack<>();

	public StringParser(String stringIn) {
		string = stringIn;
	}

	/////////////////////////
	// Position Management //
	/////////////////////////

	public int getPos() {
		return curPos;
	}

	public void advance(int count) {
		curPos += count;
	}

	public void advance() {
		advance(1);
	}

	public void skipChars(String chars)
	{
		while (checkForAnyCharIn(chars)) {
			advance();
		}
	}

	public void moveTo(int pos) {
		curPos = pos;
	}

	public void moveToEnd() {
		moveTo(string.length());
	}

	public void save() {
		posStack.push(curPos);
	}

	public void restore() {
		curPos = posStack.pop();
	}

	public void forget() {
		posStack.pop();
	}

	public void advanceToAssert(String str)
	{
		int result = findNext(str);
		if (result == -1) {
			throw new IllegalStateException("When working on line: \"" + getCurrentLine() + "\"");
		}
		moveTo(result);
	}

	public void advanceToAfterAssert(String str)
	{
		advanceToAssert(str);
		advance(str.length());
	}

	public void advanceToAfterRegex(String regex)
	{
		Matcher matcher = Pattern.compile(regex).matcher(string);
		if (matcher.find(curPos))
		{
			moveTo(matcher.start(0));
			advance(matcher.group(0).length());
		}
	}

	public String advanceToNextOneOf(String... toFindSubStrs)
	{
		FindNextOneOfResult result = findNextOneOf(toFindSubStrs);
		if (result == null) {
			return null;
		}
		moveTo(result.pos);
		return result.foundSubStr;
	}

	public String advanceToNextOneOfAssert(String... toFindSubStrs)
	{
		FindNextOneOfResult result = findNextOneOf(toFindSubStrs);
		if (result == null) {
			throw new IllegalStateException("When working on line: \"" + getCurrentLine() + "\"");
		}
		moveTo(result.pos);
		return result.foundSubStr;
	}

	public String advanceToAfterNextOneOf(String nonMatchWhitelistChars,
		boolean useNonMatchWhitelistChars, String... toFindSubStrs)
	{
		FindNextOneOfResult result = findNextOneOf(nonMatchWhitelistChars, useNonMatchWhitelistChars, toFindSubStrs);
		if (result == null) {
			return null;
		}
		moveTo(result.pos + result.foundSubStr.length());
		return result.foundSubStr;
	}

	public String advanceToAfterNextOneOf(String... toFindSubStrs)
	{
		FindNextOneOfResult result = findNextOneOf(toFindSubStrs);
		if (result == null) {
			return null;
		}
		moveTo(result.pos + result.foundSubStr.length());
		return result.foundSubStr;
	}

	public String advanceToAfterNextOneOfAssert(String nonMatchWhitelistChars,
		boolean useNonMatchWhitelistChars, String... toFindSubStrs)
	{
		FindNextOneOfResult result = findNextOneOf(nonMatchWhitelistChars, useNonMatchWhitelistChars, toFindSubStrs);
		if (result == null) {
			throw new IllegalStateException("When working on line \"" + getCurrentLine() + "\"");
		}
		moveTo(result.pos + result.foundSubStr.length());
		return result.foundSubStr;
	}

	public String advanceToAfterNextOneOfAssert(String... toFindSubStrs)
	{
		FindNextOneOfResult result = findNextOneOf(null, false, toFindSubStrs);
		if (result == null) {
			throw new IllegalStateException("When working on line: \"" + getCurrentLine() + "\"");
		}
		moveTo(result.pos + result.foundSubStr.length());
		return result.foundSubStr;
	}

	public void advanceToBalancedAssert(String openStr, String closeStr, int curLevel)
	{
		boolean hitOpen = curLevel > 0;
		int minCheckLen = Math.min(openStr.length(), closeStr.length());
		int endIndex = string.length() - minCheckLen;

		save();
		for (int checkPos = curPos; checkPos <= endIndex; ++checkPos)
		{
			moveTo(checkPos);

			if (checkForSubStr(openStr))
			{
				hitOpen = true;
				++curLevel;
			}

			if (checkForSubStr(closeStr)) {
				--curLevel;
			}

			if (hitOpen && curLevel == 0)
			{
				forget();
				return;
			}
		}

		restore();
		throw new IllegalStateException("When working on line: \"" + getCurrentLine() + "\"");
	}

	public void advanceToBalancedAssert(String openStr, String closeStr) {
		advanceToBalancedAssert(openStr, closeStr, 0);
	}

	public void advanceToAfterBalancedAssert(String openStr, String closeStr, int curLevel)
	{
		advanceToBalancedAssert(openStr, closeStr, curLevel);
		advance(closeStr.length());
	}

	public void advanceToAfterBalancedAssert(String openStr, String closeStr) {
		advanceToAfterBalancedAssert(openStr, closeStr, 0);
	}

	///////////////
	// Capturing //
	///////////////

	public void startCapture() {
		captureStack.push(curPos);
	}

	public String endCapture() {
		return string.substring(captureStack.pop(), curPos);
	}

	public String getCurrentLine()
	{
		save();
		moveTo(findCurrentLineStart());
		startCapture();
		if (advanceToNextOneOf("\r\n", "\n") == null) {
			moveToEnd();
		}
		String line = endCapture();
		restore();
		return line;
	}

	//////////////
	// Checking //
	//////////////

	public boolean checkForSubStr(String subStr, int offset)
	{
		int curPosOffset = curPos + offset;
		int checkEnd = curPosOffset + subStr.length();
		return curPosOffset >= 0 && checkEnd <= string.length()
			&& string.substring(curPosOffset, checkEnd).equals(subStr);
	}

	public boolean checkForSubStr(String subStr) {
		return checkForSubStr(subStr, 0);
	}

	public boolean checkForAnyCharIn(String chars) {
		return curPos < string.length() && chars.contains(string.substring(curPos, curPos + 1));
	}

	public boolean checkEscaped(int offset)
	{
		int escapeCharCount = 0;
		for (int i = offset - 1; checkForSubStr("\\", i); --i) {
			++escapeCharCount;
		}
		return escapeCharCount % 2 != 0;
	}

	/////////////
	// Finding //
	/////////////

	public int findNext(String subStr) {
		return string.indexOf(subStr, curPos);
	}

	public int findCurrentLineStart()
	{
		int foundLineStart = 0;
		save();
		while (curPos > 0)
		{
			if (checkForSubStr("\n", -1))
			{
				foundLineStart = curPos;
				break;
			}
			else {
				advance(-1);
			}
		}
		restore();
		return foundLineStart;
	}

	public int calculateColumn() {
		return curPos - findCurrentLineStart();
	}

	public static class FindNextOneOfResult
	{
		String foundSubStr;
		int pos;

		public FindNextOneOfResult(String pFoundSubStr, int pPos)
		{
			foundSubStr = pFoundSubStr;
			pos = pPos;
		}
	}

	public FindNextOneOfResult findNextOneOf(String nonMatchWhitelistChars,
		boolean useNonMatchWhitelistChars, String... toFindSubStrs)
	{
		int minCheckLen = Integer.MAX_VALUE;
		for (String temp : toFindSubStrs)
		{
			if (temp.length() < minCheckLen) {
				minCheckLen = temp.length();
			}
		}

		save();

		int endIndex = string.length() - minCheckLen;
		for (int checkPos = curPos; checkPos <= endIndex; ++checkPos)
		{
			moveTo(checkPos);

			for (String checkStr : toFindSubStrs)
			{
				if (checkForSubStr(checkStr))
				{
					restore();
					return new FindNextOneOfResult(checkStr, checkPos);
				}
			}

			if (useNonMatchWhitelistChars && !checkForAnyCharIn(nonMatchWhitelistChars)) {
				break;
			}
		}

		restore();
		return null;
	}

	public FindNextOneOfResult findNextOneOf(String... toFindSubStrs) {
		return findNextOneOf(null, false, toFindSubStrs);
	}
}
