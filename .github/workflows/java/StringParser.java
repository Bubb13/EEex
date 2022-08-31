
import java.util.Stack;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class StringParser
{
	private final String string;
	private int curPos = 0;

	private final Stack<Integer> captureStack = new Stack<>();

	private final Stack<Integer> posStack = new Stack<>();

	public StringParser(String stringIn)
	{
		string = stringIn;
	}

	public int findNext(String subStr)
	{
		return string.indexOf(subStr, curPos);
	}

	public int getPos()
	{
		return curPos;
	}

	public int findPreviousLineStart()
	{
		int foundLineStart = 0;
		save();
		while (curPos > 2)
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

	public int calculateColumn()
	{
		return curPos - findPreviousLineStart();
	}

	public String getCurrentLine()
	{
		save();
		moveTo(findPreviousLineStart());
		startCapture();
		if (advanceToNextOneOf("\r\n", "\n") == null) {
			moveToEnd();
		}
		String line = endCapture();
		restore();
		return line;
	}

	public void save()
	{
		posStack.push(curPos);
	}

	public void startCapture()
	{
		captureStack.push(curPos);
	}

	public String endCapture()
	{
		return string.substring(captureStack.pop(), curPos);
	}

	public void advance(int count)
	{
		curPos += count;
	}

	public void advance()
	{
		advance(1);
	}

	public void moveTo(int pos)
	{
		curPos = pos;
	}

	public void restore()
	{
		curPos = posStack.pop();
	}

	public void forget()
	{
		posStack.pop();
	}

	public boolean checkBehindSpecial()
	{
		if (curPos == 0) return true;
		String behindChar = string.substring(curPos - 1, curPos);
		return behindChar.equals(" ") || behindChar.equals("\t") || behindChar.equals("\r") || behindChar.equals("\n");
	}

	public boolean checkForSubStr(String subStr, int offset)
	{
		int curPosOffset = curPos + offset;
		int checkEnd = curPosOffset + subStr.length();
		return curPosOffset >= 0 && checkEnd <= string.length() && string.substring(curPosOffset, checkEnd).equals(subStr);
	}

	public boolean checkForSubStr(String subStr)
	{
		return checkForSubStr(subStr, 0);
	}

	public boolean checkForChars(String chars) {
		return curPos < string.length() && chars.contains(string.substring(curPos, curPos + 1));
	}

	public static class FindNextResult
	{
		String foundSubStr;
		int pos;

		public FindNextResult(String pFoundSubStr, int pPos)
		{
			foundSubStr = pFoundSubStr;
			pos = pPos;
		}
	}

	public void skipChars(String chars)
	{
		while (checkForChars(chars)) {
			advance();
		}
	}

	public FindNextResult findNextOneOf(String nonMatchWhitelistChars,
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
				if (checkStr.startsWith("^"))
				{
					if (checkBehindSpecial() && checkForSubStr(checkStr.substring(1)))
					{
						restore();
						return new FindNextResult(checkStr, checkPos);
					}
				}
				else if (checkForSubStr(checkStr))
				{
					restore();
					return new FindNextResult(checkStr, checkPos);
				}
			}

			if (useNonMatchWhitelistChars && !checkForChars(nonMatchWhitelistChars)) {
				break;
			}
		}

		restore();
		return null;
	}

	public FindNextResult findNextOneOf(String... toFindSubStrs)
	{
		return findNextOneOf(null, false, toFindSubStrs);
	}

	public String advanceToAfterNextOneOf(String... toFindSubStrs)
	{
		FindNextResult result = findNextOneOf(toFindSubStrs);
		if (result == null) {
			return null;
		}
		moveTo(result.pos + result.foundSubStr.length());
		return result.foundSubStr;
	}

	public String advanceToAfterNextOneOf(String nonMatchWhitelistChars,
		boolean useNonMatchWhitelistChars, String... toFindSubStrs)
	{
		FindNextResult result = findNextOneOf(nonMatchWhitelistChars, useNonMatchWhitelistChars, toFindSubStrs);
		if (result == null) {
			return null;
		}
		moveTo(result.pos + result.foundSubStr.length());
		return result.foundSubStr;
	}

	public String advanceToNextOneOf(String... toFindSubStrs)
	{
		FindNextResult result = findNextOneOf(toFindSubStrs);
		if (result == null) {
			return null;
		}
		moveTo(result.pos);
		return result.foundSubStr;
	}

	public String advanceToNextOneOfAssert(String... toFindSubStrs)
	{
		FindNextResult result = findNextOneOf(toFindSubStrs);
		if (result == null) {
			throw new IllegalStateException("When working on line: \"" + getCurrentLine() + "\"");
		}
		moveTo(result.pos);
		return result.foundSubStr;
	}

	public String advanceToAfterNextOneOfAssert(String nonMatchWhitelistChars,
		boolean useNonMatchWhitelistChars, String... toFindSubStrs)
	{
		FindNextResult result = findNextOneOf(nonMatchWhitelistChars, useNonMatchWhitelistChars, toFindSubStrs);
		if (result == null) {
			throw new IllegalStateException("When working on line \"" + getCurrentLine() + "\"");
		}
		moveTo(result.pos + result.foundSubStr.length());
		return result.foundSubStr;
	}

	public String advanceToAfterNextOneOfAssert(String... toFindSubStrs)
	{
		FindNextResult result = findNextOneOf(null, false, toFindSubStrs);
		if (result == null) {
			throw new IllegalStateException("When working on line: \"" + getCurrentLine() + "\"");
		}
		moveTo(result.pos + result.foundSubStr.length());
		return result.foundSubStr;
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

	public void moveToEnd()
	{
		moveTo(string.length());
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

	public void advanceToBalancedAssert(String openStr, String closeStr, int curLevel)
	{
		boolean hitOpen = curLevel > 0;
		int minCheckLen = Math.min(openStr.length(), closeStr.length());
		int endIndex = string.length() - minCheckLen;

		save();
		for (int checkPos = curPos; checkPos <= endIndex; ++checkPos)
		{
			moveTo(checkPos);

			if (checkForSubStr(openStr)) {
				hitOpen = true;
				++curLevel;
			}

			if (checkForSubStr(closeStr)) {
				--curLevel;
			}

			if (hitOpen && curLevel == 0) {
				forget();
				return;
			}
		}

		restore();
		throw new IllegalStateException("When working on line: \"" + getCurrentLine() + "\"");
	}

	public void advanceToBalancedAssert(String openStr, String closeStr)
	{
		advanceToBalancedAssert(openStr, closeStr, 0);
	}

	public void advanceToAfterBalancedAssert(String openStr, String closeStr, int curLevel)
	{
		advanceToBalancedAssert(openStr, closeStr, curLevel);
		advance(closeStr.length());
	}

	public void advanceToAfterBalancedAssert(String openStr, String closeStr)
	{
		advanceToAfterBalancedAssert(openStr, closeStr, 0);
	}
}
