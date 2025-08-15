
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.nio.file.FileSystems;
import java.nio.file.FileVisitResult;
import java.nio.file.FileVisitor;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.attribute.BasicFileAttributes;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class UpdateDocs
{
	private static String BASE_PATH;

	private static class FieldInfo
	{
		String name;
		int offset;
		String type;

		FieldInfo(String name, int offset, String type)
		{
			this.name = name;
			this.offset = offset;
			this.type = type;
		}
	}

	private static class StructInfo
	{
		String name;
		int size;
		ArrayList<FieldInfo> fieldInfo = new ArrayList<>();

		public StructInfo(String name, int size)
		{
			this.name = name;
			this.size = size;
		}
	}

	private static HashMap<String, StructInfo> requestStructInfo(HashSet<String> availableRefTargets)
		throws IOException
	{
		String requestTypesOutName = BASE_PATH + "\\python\\in\\request_types.txt";
		new FileWriter(requestTypesOutName).close();
		PrintWriter requestTypesOut = new PrintWriter(new BufferedWriter(
			new FileWriter(requestTypesOutName, true)), true);

		for (String refTarget : availableRefTargets) {
			requestTypesOut.println(refTarget);
		}

		requestTypesOut.flush();
		requestTypesOut.close();

		Process requestProcess = new ProcessBuilder(BASE_PATH + "\\python\\RUN_REQUEST.bat")
			.directory(new File(BASE_PATH + "\\python"))
			.start();

		try {
			requestProcess.waitFor();
		}
		catch (InterruptedException ignored){}

		HashMap<String, StructInfo> toReturn = new HashMap<>();
		StructInfo currentStructInfo = null;

		for (String line : Files.readAllLines(new File(BASE_PATH + "\\python\\out\\types.txt").toPath()))
		{
			if (currentStructInfo == null && line.startsWith(":"))
			{
				String[] split = line.substring(1).split("\\|");
				String name = split[0];
				int size = Integer.parseInt(split[1]);
				currentStructInfo = new StructInfo(name, size);
			}
			else if (currentStructInfo != null)
			{
				if (line.equals(":end"))
				{
					toReturn.put(currentStructInfo.name, currentStructInfo);
					currentStructInfo = null;
				}
				else
				{
					String[] split = line.split("\\|");
					String name = split[0];
					int offset = Integer.parseInt(split[1], 16);
					String type = split[2];
					currentStructInfo.fieldInfo.add(new FieldInfo(name, offset, type));
				}
			}
		}

		return toReturn;
	}

	private static ArrayList<File> getStructFiles(String folderStart)
	{
		ArrayList<File> structFiles = new ArrayList<>();

		ArrayDeque<File> folderQueue = new ArrayDeque<>();
		folderQueue.addFirst(new File(folderStart));

		while (!folderQueue.isEmpty())
		{
			File folder = folderQueue.removeFirst();

			File[] files = folder.listFiles();
			if (files == null) {
				continue;
			}

			for (File file : files)
			{
				if (file.isDirectory()) {
					folderQueue.addLast(file);
				}
				else if (file.getName().equals("index.rst")
					&& !folder.getName().equals("EE Game Structures (x86)"))
				{
					structFiles.add(file);
				}
			}
		}

		return structFiles;
	}

	private static class TableMaker
	{
		private final int rowLength;
		private final ArrayList<TableRow> rows = new ArrayList<>();

		private static class TableRow
		{
			String[] cells;

			public TableRow(String... rowValues) {
				cells = rowValues;
			}

			public String getCell(int cellIndex) {
				return cells[cellIndex];
			}

			public int getCellLength(int cellIndex) {
				return cells[cellIndex].length();
			}
		}

		public TableMaker(int rowLength) {
			this.rowLength = rowLength;
		}

		public void addRow(String... rowValues)
		{
			if (rowValues.length != rowLength) {
				throw new IllegalArgumentException();
			}

			rows.add(new TableRow(rowValues));
		}

		public int getColumnLongestLength(int columnIndex)
		{
			int max = 0;
			for (TableRow row : rows)
			{
				int cellLength = row.getCellLength(columnIndex);
				if (cellLength > max) {
					max = cellLength;
				}
			}
			return max;
		}

		public String build()
		{
			StringBuilder builder = new StringBuilder();
			StringBuilder tableSeparatorLineBuilder = new StringBuilder();

			int[] columnDashCounts = new int[rowLength];
			for (int i = 0; i < rowLength; ++i)
			{
				int columnMaxLength = getColumnLongestLength(i);
				int dashCount = columnMaxLength > 0 ? columnMaxLength + 2 : 0;
				columnDashCounts[i] = dashCount;
				tableSeparatorLineBuilder.append("+");
				tableSeparatorLineBuilder.append("-".repeat(dashCount));
			}

			String tableSeparatorLine = tableSeparatorLineBuilder.append("+")
				.append(System.lineSeparator()).toString();

			for (int i = 0; i < rows.size(); ++i)
			{
				TableRow row = rows.get(i);

				if (i != 1) {
					builder.append(tableSeparatorLine);
				}
				else {
					builder.append(tableSeparatorLine.replaceAll("-", "="));
				}

				for (int j = 0; j < rowLength; ++j)
				{
					builder.append("|");

					String cell = row.getCell(j);
					int cellLength = cell.length();

					builder.append(" ");
					builder.append(cell);
					builder.append(" ".repeat(columnDashCounts[j] - cellLength - 1));
				}

				builder.append("|").append(System.lineSeparator());
			}

			builder.append(tableSeparatorLine);
			return builder.toString();
		}
	}

	private static String makeTable(String structName, HashMap<String, StructInfo> structInfoMap)
	{
		String idaStructName = structName.startsWith("<unnamed-type-")
			? "<unnamed_type_" + structName.substring(14)
			: structName;

		StructInfo structInfo = structInfoMap.get(idaStructName);

		if (structInfo == null)
		{
			//System.err.println("Unable to find struct info for " + idaStructName);
			return null;
		}

		TableMaker tableMaker = new TableMaker(4);
		tableMaker.addRow("**Offset**", "**Size (Total: "
			+ structInfo.size + ")**", "**Type**", "**Field**");

		for (int i = 0; i < structInfo.fieldInfo.size(); ++i)
		{
			FieldInfo fieldInfo = structInfo.fieldInfo.get(i);

			int fieldSize = i < structInfo.fieldInfo.size() - 1
				? structInfo.fieldInfo.get(i + 1).offset - fieldInfo.offset
				: structInfo.size - fieldInfo.offset;

			boolean isTypeBlank = fieldInfo.type.equals("<blank>");
			tableMaker.addRow(
				isTypeBlank ? "" : String.format("0x%X", fieldInfo.offset),
				String.valueOf(fieldSize),
				isTypeBlank ? "" : fieldInfo.type,
				fieldInfo.name);
		}

		return tableMaker.build();
	}

	private static PrintWriter openTextWriter(String path) throws IOException
	{
		File file = new File(path);
		File parent = file.getParentFile();
		if (parent != null && !parent.exists())
		{
			if (!parent.mkdirs()) {
				throw new IllegalStateException();
			}
		}
		new FileWriter(file).close();
		return new PrintWriter(new BufferedWriter(new FileWriter(file, true)), true);
	}

	private static void writeHeader(PrintWriter writer, String text)
	{
		String topBottom = "=".repeat(text.length());
		writer.println(topBottom);
		writer.println(text);
		writer.println(topBottom);
		writer.println();
	}

	private static final Pattern REF_TARGET_PATTERN = Pattern.compile("\\.\\. _(.*?[^\\\\]):");
	private static final Pattern TABLE_END_PATTERN = Pattern.compile("\\+\r?\n(?!\\|)");

	private static void updateDocsStructures(String folderStart) throws IOException
	{
		ArrayList<File> structFiles = getStructFiles(folderStart);
		HashSet<String> availableRefTargets = new HashSet<>();

		for (File structFile : structFiles)
		{
			String fileContents = Files.readString(structFile.toPath());
			Matcher match = REF_TARGET_PATTERN.matcher(fileContents);
			while (match.find()) {
				availableRefTargets.add(match.group(1).replaceAll("\\\\", ""));
			}
		}

		HashMap<String, StructInfo> structInfo = requestStructInfo(availableRefTargets);

		for (File structFile : structFiles)
		{
			String fileContents = Files.readString(structFile.toPath());
			Matcher match = REF_TARGET_PATTERN.matcher(fileContents);

			int findStartIndex = 0;
			while (match.find(findStartIndex))
			{
				findStartIndex = match.end();

				// Note: Find table
				int tableStart = fileContents.indexOf("+-", match.end());
				if (tableStart == -1) {
					continue;
				}

				// Note: Make sure I'm the refTarget that controls the table
				Matcher match2 = REF_TARGET_PATTERN.matcher(fileContents);
				if (match2.find(match.end()) && match2.start() < tableStart) {
					continue;
				}

				String structName = match.group(1).replaceAll("\\\\", "");

				Matcher tableEndMatch = TABLE_END_PATTERN.matcher(fileContents);
				if (tableEndMatch.find(tableStart))
				{
					String newTable = makeTable(structName, structInfo);

					if (newTable == null)
					{
						System.err.println("Failed to generate table for \"" + structName + "\"");
						continue;
					}

					fileContents = fileContents.substring(0, tableStart)
						+ newTable
						+ fileContents.substring(tableEndMatch.end());

					match = REF_TARGET_PATTERN.matcher(fileContents);
					findStartIndex = tableStart + newTable.length();
				}
				else {
					System.err.println("Failed to replace table for \"" + structName
						+ "\" (couldn't find table end)");
				}
			}

			Files.writeString(structFile.toPath(), fileContents);
		}
	}

	private static String getNameNoExtension(File file)
	{
		String fileName = file.getName();
		int lastIndex = fileName.lastIndexOf(".");
		return fileName.substring(0, lastIndex != -1 ? lastIndex : fileName.length());
	}

	private static String getFileExtension(File file)
	{
		String fileName = file.getName();
		int lastIndex = fileName.lastIndexOf(".");
		return lastIndex > 0 ? fileName.substring(lastIndex + 1) : "";
	}

	private static class BubbDoc
	{
		public static class BubbDocParam
		{
			String name;
			String type;
			boolean typeIsUserdata;
			String defaultValue;
			String description;
		}

		public static class BubbDocReturn
		{
			String type;
			boolean typeIsUserdata;
			String defaultValue;
			String description;
		}

		String name;
		String alias;
		String instanceName;
		String deprecated;
		String mirror;
		ArrayList<BubbDocParam> params = new ArrayList<>();
		ArrayList<BubbDocReturn> returnValues = new ArrayList<>();
		BubbDocParam self;
		String summary;
		String extraComment;
		ArrayList<String> warnings = new ArrayList<>();
		ArrayList<String> notes = new ArrayList<>();
	}

	private interface UnnamedFieldHandler
	{
		void handle(String value);
	}

	private interface NamedFieldHandler
	{
		void handle(String name, String value);
	}

	private static void handleInnerDocFields(StringParser commentParser, String[] allowedFieldNames,
		 UnnamedFieldHandler unnamedFieldHandler,
		 NamedFieldHandler namedFieldHandler)
	{
		commentParser.advanceToAfterAssert("{");
		commentParser.startCapture();
		commentParser.advanceToAssert("}");
		String bubbDocInner = commentParser.endCapture();
		commentParser.advance(1);

		String[] innerSplit = bubbDocInner.split("/");
		if (innerSplit.length == 0) {
			throw new IllegalStateException("When working on line: \"" + commentParser.getCurrentLine() + "\"");
		}

		int loopStartIndex = 0;
		if (unnamedFieldHandler != null)
		{
			unnamedFieldHandler.handle(innerSplit[0].trim());
			loopStartIndex = 1;
		}

		for (int i = loopStartIndex; i < innerSplit.length; ++i)
		{
			String innerPart = innerSplit[i].trim();
			innerPart = innerPart.trim();

			StringParser innerParser = new StringParser(innerPart);

			String innerFieldName = innerParser.advanceToAfterNextOneOfAssert(
				"", true, allowedFieldNames);

			innerParser.advanceToAfterNextOneOfAssert(" \t",
				true, "=");
			innerParser.skipChars(" \t");
			innerParser.startCapture();
			innerParser.moveToEnd();
			String innerFieldValue = innerParser.endCapture().replaceAll("\r?\n[ \t]*", "");

			namedFieldHandler.handle(innerFieldName, innerFieldValue);
		}
	}

	private static String normalizeBlockComment(int startColumn, String string)
	{
		string = " ".repeat(startColumn) + string;

		String[] lines = string.split("\r?\n");
		Pattern indentPattern = Pattern.compile("^[ \t]+");
		String foundCommonIndent = "";

		for (String line : lines)
		{
			// Don't process empty lines for indent analysis
			if (line.trim().equals("")) {
				continue;
			}

			Matcher matcher = indentPattern.matcher(line);
			if (matcher.find())
			{
				String indent = matcher.group(0);
				if (indent.length() > foundCommonIndent.length())
				{
					boolean noConflict = true;
					for (String checkLine : lines)
					{
						// Don't process empty lines for indent analysis
						if (checkLine.trim().equals("")) {
							continue;
						}

						if (!checkLine.startsWith(indent))
						{
							noConflict = false;
							break;
						}
					}

					if (noConflict) {
						foundCommonIndent = indent;
					}
				}
			}
			else {
				break;
			}
		}

		StringBuilder resultBuilder = new StringBuilder();

		boolean hitMeaningfulLine = false;
		for (String line : lines)
		{
			if (line.trim().equals(""))
			{
				if (hitMeaningfulLine) {
					resultBuilder.append(System.lineSeparator());
				}
				continue;
			}
			hitMeaningfulLine = true;
			resultBuilder.append(line.substring(foundCommonIndent.length()));
			resultBuilder.append(System.lineSeparator());
		}

		string = resultBuilder.toString();

		// trim end-of-string only
		int i = string.length() - 1;
		for (; i >= 0; --i)
		{
			char character = string.charAt(i);
			if (character != ' ' && character != '\t' && character != '\r' && character != '\n') {
				break;
			}
		}

		return string.substring(0, i + 1);
	}

	private static String indentSubsequentLines(String string, String indentString)
	{
		String[] lines = string.split("\r?\n");
		StringBuilder builder = new StringBuilder();

		if (lines.length > 0)
		{
			builder.append(lines[0]);
			builder.append(System.lineSeparator());
		}

		for (int i = 1; i < lines.length; ++i)
		{
			builder.append(indentString);
			builder.append(lines[i]);
			builder.append(System.lineSeparator());
		}

		if (lines.length > 0) {
			builder.setLength(builder.length() - System.lineSeparator().length());
		}

		return builder.toString();
	}

	private static String extractBlockComment(StringParser commentParser, String... fieldsArray)
	{
		commentParser.advanceToAfterNextOneOfAssert(" \t\r\n",
			true, ":");

		int startColumn = commentParser.calculateColumn();

		commentParser.startCapture();
		if (commentParser.advanceToNextOneOf(fieldsArray) == null) {
			commentParser.moveToEnd();
		}
		return normalizeBlockComment(startColumn, commentParser.endCapture());
	}

	private static ArrayList<String> extractComments(String luaFileContents)
	{
		StringParser luaContentsParser = new StringParser(luaFileContents);
		StringBuilder lineByLineBlockCommentBuilder = new StringBuilder();
		ArrayList<String> comments = new ArrayList<>();

		while (true)
		{
			String foundSubStr = luaContentsParser.advanceToAfterNextOneOf(
				"\"", "'", "[[", "--[[", "--");

			if (foundSubStr == null) {
				break;
			}

			switch (foundSubStr)
			{
				case "\"" ->
				{
					do {
						luaContentsParser.advanceToAfterAssert("\"");
					}
					while (luaContentsParser.checkEscaped(-1));
				}
				case "'" ->
				{
					do {
						luaContentsParser.advanceToAfterAssert("'");
					}
					while (luaContentsParser.checkEscaped(-1));
				}
				case "[[" -> {
					luaContentsParser.advanceToAfterAssert("]]");
				}
				case "--[[" ->
				{
					luaContentsParser.startCapture();
					String advancedTo = luaContentsParser.advanceToNextOneOfAssert("--]]", "]]");
					String capture = luaContentsParser.endCapture();
					comments.add(capture);
					luaContentsParser.advance(advancedTo.length());
				}
				case "--" ->
				{
					while (true)
					{
						luaContentsParser.startCapture();
						if (luaContentsParser.advanceToAfterNextOneOf("\r\n", "\n") != null) {
							lineByLineBlockCommentBuilder.append(luaContentsParser.endCapture());
						}
						else
						{
							luaContentsParser.moveToEnd();
							lineByLineBlockCommentBuilder.append(luaContentsParser.endCapture());
							lineByLineBlockCommentBuilder.append(System.lineSeparator());
						}

						luaContentsParser.save();
						if (luaContentsParser.advanceToAfterNextOneOf(" \t",
							true, "--") == null)
						{
							luaContentsParser.restore();
							break;
						}
						luaContentsParser.forget();
					}

					int lineByLineBlockCommentBuilderLen = lineByLineBlockCommentBuilder.length();
					if (lineByLineBlockCommentBuilderLen > 0)
					{
						lineByLineBlockCommentBuilder.setLength(lineByLineBlockCommentBuilderLen -
							System.lineSeparator().length());
					}

					comments.add(lineByLineBlockCommentBuilder.toString());
					lineByLineBlockCommentBuilder.setLength(0);
				}
			}
		}

		return comments;
	}

	private static BubbDoc generateBubbDocFromComment(String comment)
	{
		StringParser commentParser = new StringParser(comment);
		String found = commentParser.advanceToAfterNextOneOf(
			" \t\r\n", true, "@bubb_doc");

		if (found == null) {
			return null;
		}

		BubbDoc doc = new BubbDoc();

		handleInnerDocFields(commentParser, new String[]{ "alias", "instance_name" },
			(String docName) -> {
				doc.name = docName;
			},
			(String name, String value) ->
			{
				switch (name)
				{
					case "alias" -> {
						doc.alias = value;
					}
					case "instance_name" -> {
						doc.instanceName = value;
					}
				}
			});

		String[] fieldsArray = new String[]{ "@deprecated", "@mirror", "@param",
			"@return", "@self", "@summary", "@extra_comment", "@warning", "@note" };

		while (true)
		{
			found = commentParser.advanceToAfterNextOneOf(fieldsArray);

			if (found == null) {
				break;
			}

			switch (found)
			{
				case "@deprecated" -> {
					doc.deprecated = extractBlockComment(commentParser, fieldsArray);
				}
				case "@mirror" ->
				{
					handleInnerDocFields(commentParser, new String[]{},
						(String mirrorName) -> {
							doc.mirror = mirrorName;
						},
						null);
				}
				case "@param", "@self" ->
				{
					BubbDoc.BubbDocParam param = new BubbDoc.BubbDocParam();

					handleInnerDocFields(commentParser, new String[]{ "type", "usertype", "default" },
						(String paramName) -> {
							param.name = paramName;
						},
						(String name, String value) ->
						{
							switch (name)
							{
								case "type" ->
								{
									param.type = value;
									param.typeIsUserdata = false;
								}
								case "usertype" ->
								{
									param.type = value;
									param.typeIsUserdata = true;
								}
								case "default" -> {
									param.defaultValue = value;
								}
							}
						});

					param.description = extractBlockComment(commentParser, fieldsArray);

					if (found.equals("@param")) {
						doc.params.add(param);
					}
					else {
						doc.self = param;
					}
				}
				case "@return" ->
				{
					BubbDoc.BubbDocReturn ret = new BubbDoc.BubbDocReturn();

					handleInnerDocFields(commentParser, new String[]{ "type", "usertype", "default" },
						null,
						(String name, String value) ->
						{
							switch (name)
							{
								case "type" ->
								{
									ret.type = value;
									ret.typeIsUserdata = false;
								}
								case "usertype" ->
								{
									ret.type = value;
									ret.typeIsUserdata = true;
								}
								case "default" -> {
									ret.defaultValue = value;
								}
							}
						});

					ret.description = extractBlockComment(commentParser, fieldsArray);
					doc.returnValues.add(ret);
				}
				case "@summary" -> {
					doc.summary = extractBlockComment(commentParser, fieldsArray);
				}
				case "@extra_comment" -> {
					doc.extraComment = extractBlockComment(commentParser, fieldsArray);
				}
				case "@warning" -> {
					doc.warnings.add(extractBlockComment(commentParser, fieldsArray));
				}
				case "@note" -> {
					doc.notes.add(extractBlockComment(commentParser, fieldsArray));
				}
			}
		}

		return doc;
	}

	private static void fillDocMap(Map<String, Map<String, BubbDoc>> bubbDocs, String fullFunctionName,
		BubbDoc fillValue)
	{
		Pattern nameNoModifierPattern = Pattern.compile("^EEex_(\\S+?)_(\\S+)");
		Pattern nameWithModifierPattern = Pattern.compile("^EEex_(\\S+?)_(\\S+?)_(\\S+)");

		String fileName;
		//String functionName;

		Matcher nameWithModifierMatcher = nameWithModifierPattern.matcher(fullFunctionName);

		if (nameWithModifierMatcher.find())
		{
			String modifier = nameWithModifierMatcher.group(2);
			if (modifier.equals("Hook") || modifier.equals("Private")) {
				return;
			}

			fileName = nameWithModifierMatcher.group(1);
			//functionName = nameWithModifierMatcher.group(2) + "_" + nameWithModifierMatcher.group(3);
		}
		else
		{
			Matcher nameNoModifierMatcher = nameNoModifierPattern.matcher(fullFunctionName);
			if (nameNoModifierMatcher.find())
			{
				fileName = nameNoModifierMatcher.group(1);
				//functionName = nameNoModifierMatcher.group(2);
			}
			else {
				return;
			}
		}

		Map<String, BubbDoc> docMap = bubbDocs.computeIfAbsent(fileName, k -> new HashMap<>());
		docMap.put(fullFunctionName, fillValue);
	}

	private static final Pattern LUA_FUNCTION_PATTERN = Pattern.compile(
		"(local\\s+)?function\\s+(\\S+)\\s*\\([\\s\\S]*?\\)");

	private static String replaceRole(String str, String macroString, String roleName)
	{
		macroString = "(@" + macroString + "[ \t]*\\([ \t]*(.*?)[ \t]*\\))";
		str = str.replaceAll("(?<=\\S)" + macroString, "$1");
		str = str.replaceAll(macroString + "(?=\\S)", "$1\\\\");
		str = str.replaceAll("[ \t]+" + macroString, " $1");
		str = str.replaceAll(macroString + "[ \t]+", "$1 ");
		str = str.replaceAll(macroString + "[ \t]+(?=\r?\n)", "$1");
		return str.replaceAll(macroString, ":" + roleName + ":`$2`");
	}

	private static String replaceBoldItalic(String str)
	{
		String macroString = "(\\*\\*\\*[ \t]*(.*?)[ \t]*\\*\\*\\*)";
		str = str.replaceAll("(?<=\\S)" + macroString, "$1");
		str = str.replaceAll(macroString + "(?=\\S)", "$1\\\\");
		str = str.replaceAll("[ \t]+" + macroString, " $1");
		str = str.replaceAll(macroString + "[ \t]+", "$1 ");
		str = str.replaceAll(macroString + "[ \t]+(?=\r?\n)", "$1");
		return str.replaceAll(macroString, ":bold-italic:`$2`");
	}

	private static String replacePre(String str)
	{
		String macroString = "(@\\|[ \t]*(.*?)[ \t]*@\\|)";
		str = str.replaceAll("(?<=\\S)" + macroString, "$1");
		str = str.replaceAll(macroString + "(?=\\S)", "$1\\\\");
		str = str.replaceAll("[ \t]+" + macroString, " $1");
		str = str.replaceAll(macroString + "[ \t]+", "$1 ");
		str = str.replaceAll(macroString + "[ \t]+(?=\r?\n)", "$1");
		return str.replaceAll(macroString, ":raw-html:`<pre>` $2 :raw-html:`</pre>`");
	}

	private static String preprocessDescription(String str)
	{
		str = str.replaceAll("(?<=\\S)@EOL", "@EOL");
		str = str.replaceAll("@EOL(?=\\S)", "@EOL\\\\");
		str = str.replaceAll("\\s*@EOL\\s*", " @EOL ");
		str = str.replaceAll("@EOL", ":raw-html:`<br/>`");
		return replacePre(replaceBoldItalic(str));
	}

	private interface KeyValueProcessor<KeyType, ValueType> {
		void process(KeyType key, ValueType value) throws Exception;
	}

	private static <KeyType, ValueType> void iterateMapAsSorted(Map<KeyType, ValueType> map,
		Comparator<KeyType> comparator, KeyValueProcessor<KeyType, ValueType> processor) throws Exception
	{
		List<Map.Entry<KeyType, ValueType>> entries = new ArrayList<>(map.entrySet());
		entries.sort((o1, o2) -> comparator.compare(o1.getKey(), o2.getKey()));
		for (Map.Entry<KeyType, ValueType> entry : entries) {
			processor.process(entry.getKey(), entry.getValue());
		}
	}

	private static void deletePath(Path path) throws IOException
	{
		if (!path.getName(path.getNameCount() - 1).toString().equals("EEex Functions")) {
			throw new IllegalStateException("[!!!] Attempted to recursively delete something unexpected [!!!]");
		}

		Files.walkFileTree(path, new FileVisitor<>()
		{
			@Override
			public FileVisitResult preVisitDirectory(Path dir, BasicFileAttributes attrs) {
				return FileVisitResult.CONTINUE;
			}

			@Override
			public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) throws IOException
			{
				Files.delete(file);
				return FileVisitResult.CONTINUE;
			}

			@Override
			public FileVisitResult visitFileFailed(Path file, IOException exc) {
				return FileVisitResult.CONTINUE;
			}

			@Override
			public FileVisitResult postVisitDirectory(Path dir, IOException exc) throws IOException
			{
				Files.delete(dir);
				return FileVisitResult.CONTINUE;
			}
		});
	}

	private static void createFunctionDocs(String folderSrcPath, String folderOutPathStr) throws Exception
	{
		HashMap<String, Map<String, BubbDoc>> bubbDocs = new HashMap<>();

		for (File srcFile : new File(folderSrcPath).listFiles())
		{
			if (srcFile.isFile() && getFileExtension(srcFile).equalsIgnoreCase("LUA"))
			{
				String luaFileContents = Files.readString(srcFile.toPath());

				// Find comments

				ArrayList<String> comments = extractComments(luaFileContents);

				// Find all non-local functions

				Matcher luaFunctionMatcher = LUA_FUNCTION_PATTERN.matcher(luaFileContents);
				while (luaFunctionMatcher.find())
				{
					// No local functions
					if (luaFunctionMatcher.group(1) != null) {
						break;
					}

					String fullFunctionName = luaFunctionMatcher.group(2);
					fillDocMap(bubbDocs, fullFunctionName, null);
				}

				// Parsing comment blocks

				for (String comment : comments)
				{
					BubbDoc doc = generateBubbDocFromComment(comment);
					if (doc != null) {
						fillDocMap(bubbDocs, doc.name, doc);
					}
				}
			}
		}

		Path folderOutPath = FileSystems.getDefault().getPath(folderOutPathStr);
		deletePath(folderOutPath);
		Files.createDirectory(folderOutPath);

		PrintWriter mainIndexWriter = openTextWriter(folderOutPathStr + File.separator
			+ "index.rst");

		mainIndexWriter.println(
   		"""
		.. _EEex Functions:

		==============
		EEex Functions
		==============

		.. note:: EEex functions are located in Lua files provided by the EEex WeiDU installer and installed into the ``override`` folder of the game. The functions have been organized into related categories to better navigate and browse.

		.. toctree::
		   :maxdepth: 2
		""");

		iterateMapAsSorted(bubbDocs, String::compareToIgnoreCase,
			(String fileName, Map<String, BubbDoc> funcDocs) ->
		{
			mainIndexWriter.println("   " + fileName + "/index");

			PrintWriter writer = openTextWriter(folderOutPathStr + File.separator
				+ fileName + File.separator + "index.rst");

			writer.println(".. role:: raw-html(raw)" + System.lineSeparator() +
				"   :format: html" + System.lineSeparator());

			writer.println(".. role:: underline" + System.lineSeparator() +
				"   :class: underline" + System.lineSeparator());

			writer.println(".. role:: bold-italic" + System.lineSeparator() +
				"   :class: bold-italic" + System.lineSeparator());

			writeHeader(writer, fileName);

			iterateMapAsSorted(funcDocs, String::compareToIgnoreCase, (String funcName, BubbDoc doc) ->
			{
				String docName = funcName;

				writer.println(".. _" + funcName + ":");
				writer.println();
				writer.println(docName);
				writer.println("^".repeat(docName.length()));
				writer.println();

				if (doc == null)
				{
					writer.println(".. warning::");
					writer.println("   This function is currently undocumented.");
					writer.println();
					return;
				}

				if (doc.alias != null)
				{
					StringBuilder aliasBuilder = new StringBuilder();

					String[] aliases = doc.alias.split("\\|");
					for (String alias : aliases)
					{
						aliasBuilder.append("``");
						aliasBuilder.append(alias);
						aliasBuilder.append("``");
						aliasBuilder.append(", ");
					}

					aliasBuilder.setLength(aliasBuilder.length() - 2);
					writer.println("**Aliases:** " + aliasBuilder);
				}

				if (doc.instanceName != null) {
					writer.println("**Instance Name:** ``" + doc.instanceName + "``");
				}

				if (doc.deprecated != null)
				{
					writer.println(".. warning::");
					writer.println("   **Deprecated:** "
						+ indentSubsequentLines(doc.deprecated, "   "));
					writer.println();
				}

				if (doc.summary != null)
				{
					writer.println();
					writer.println(".. admonition:: Summary");
					writer.println();
					writer.println("   " + indentSubsequentLines(preprocessDescription(doc.summary), "   "));
					writer.println();
				}

				for (String warning : doc.notes)
				{
					writer.println();
					writer.println(".. note::");
					writer.println(indentSubsequentLines("   " + preprocessDescription(warning),
						"   "));
					writer.println();
				}

				for (String warning : doc.warnings)
				{
					writer.println();
					writer.println(".. warning::");
					writer.println(indentSubsequentLines("   " + preprocessDescription(warning),
						"   "));
					writer.println();
				}

				if (doc.self != null || doc.params.size() > 0)
				{
					TableMaker tableMaker = new TableMaker(4);
					tableMaker.addRow("**Name**", "**Type**",
						"**Default Value**", "**Description**");

					if (doc.self != null)
					{
						String defaultString = doc.self.defaultValue != null
							? "``" + doc.self.defaultValue + "``"
							: "";
						tableMaker.addRow(doc.self.name, doc.self.type, defaultString,
							preprocessDescription(doc.self.description));
					}

					writer.println("**Parameters:**" + System.lineSeparator());
					for (BubbDoc.BubbDocParam param : doc.params)
					{
						String defaultString = param.defaultValue != null
							? "``" + param.defaultValue + "``"
							: "";
						tableMaker.addRow(param.name, param.type, defaultString,
							preprocessDescription(param.description));
					}

					writer.println(tableMaker.build());
				}

				if (doc.returnValues.size() > 0)
				{
					writer.println("**Return Values:**" + System.lineSeparator());

					TableMaker tableMaker = new TableMaker(2);
					tableMaker.addRow("**Type**", "**Description**");

					for (BubbDoc.BubbDocReturn returnValue : doc.returnValues)
					{
						tableMaker.addRow(preprocessDescription(returnValue.type),
							preprocessDescription(returnValue.description));
					}

					writer.println(tableMaker.build());
				}

				if (doc.extraComment != null) {
					writer.println(doc.extraComment);
				}

				writer.println();
			});

			writer.flush();
			writer.close();
		});
	}

	private static class FolderContents
	{
		String folderName;
		File[] files;
		int currentIterationIndex = 0;

		public FolderContents(String folderName, File[] files)
		{
			this.folderName = folderName;
			this.files = files;
		}

		@Override
		public String toString() {
			return this.folderName;
		}
	}

	private static void printFiles(String folderStart)
	{
		ArrayDeque<FolderContents> folderContentsQueue = new ArrayDeque<>();
		folderContentsQueue.addFirst(new FolderContents("<print_root>",
			new File[]{ new File(folderStart) }));

		StringBuilder indent = new StringBuilder();

		while (!folderContentsQueue.isEmpty())
		{
			FolderContents folderContents = folderContentsQueue.peekFirst();

			for (; folderContents.currentIterationIndex < folderContents.files.length;
				 ++folderContents.currentIterationIndex)
			{
				File file = folderContents.files[folderContents.currentIterationIndex];

				if (file.isFile()) {
					System.out.println(indent + file.getName());
				}
				else if (file.isDirectory())
				{
					System.out.println(indent + file.getName() + " =>");

					File[] files = file.listFiles();
					if (files != null)
					{
						folderContentsQueue.addFirst(new FolderContents(file.getName(), files));
						indent.append("    ");
						break;
					}
				}
			}

			if (folderContents.currentIterationIndex == folderContents.files.length)
			{
				folderContentsQueue.removeFirst();
				if (!folderContentsQueue.isEmpty())
				{
					++folderContentsQueue.peek().currentIterationIndex;
					indent.setLength(indent.length() - 4);
				}
			}
		}
	}

	public static void main(String[] args) throws Exception
	{
		BASE_PATH = Paths.get("").toAbsolutePath().toString();
		createFunctionDocs(args[0], args[1]);
	}
}
