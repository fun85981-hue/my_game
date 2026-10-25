class_name XlsxReader

## 极简 xlsx 读取：只依赖 Godot 自带的 ZIPReader + XMLParser。
## 返回 { 工作表名: Array[行], 行 = Array[单元格字符串] }。
## 单元格支持：共享字符串、内联字符串、数字、布尔；不处理公式、合并单元格、日期。

static func read_sheets(path: String) -> Dictionary:
	var zip := ZIPReader.new()
	if zip.open(path) != OK:
		push_warning("XlsxReader：打不开文件 %s" % path)
		return {}
	var shared := _read_shared_strings(zip)
	var result := {}
	for sheet in _read_workbook(zip):
		var target := String(sheet["target"])
		if not zip.file_exists(target):
			continue
		var bytes := zip.read_file(target)
		if bytes.is_empty():
			continue
		result[String(sheet["name"])] = _read_sheet(bytes, shared)
	zip.close()
	return result


# ---------------------------------------------------------------- 工作簿结构

static func _read_workbook(zip: ZIPReader) -> Array:
	var sheets := []
	if not zip.file_exists("xl/workbook.xml"):
		return sheets
	var bytes := zip.read_file("xl/workbook.xml")
	if bytes.is_empty():
		return sheets
	var rels := _read_rels(zip)
	var parser := XMLParser.new()
	if parser.open_buffer(bytes) != OK:
		return sheets
	while parser.read() == OK:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT and parser.get_node_name() == "sheet":
			var sheet_name := _attr(parser, "name")
			var rid := _attr(parser, "id")
			var target := String(rels.get(rid, ""))
			if target == "":
				target = "xl/worksheets/sheet%d.xml" % (sheets.size() + 1)
			sheets.append({"name": sheet_name, "target": target})
	return sheets


static func _read_rels(zip: ZIPReader) -> Dictionary:
	var result := {}
	if not zip.file_exists("xl/_rels/workbook.xml.rels"):
		return result
	var bytes := zip.read_file("xl/_rels/workbook.xml.rels")
	if bytes.is_empty():
		return result
	var parser := XMLParser.new()
	if parser.open_buffer(bytes) != OK:
		return result
	while parser.read() == OK:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT and parser.get_node_name() == "Relationship":
			var rid := _attr(parser, "Id")
			var target := _attr(parser, "Target")
			if target.begins_with("/"):
				target = target.substr(1)
			elif not target.begins_with("xl/"):
				target = "xl/" + target
			result[rid] = target
	return result


static func _read_shared_strings(zip: ZIPReader) -> PackedStringArray:
	var strings := PackedStringArray()
	if not zip.file_exists("xl/sharedStrings.xml"):
		return strings
	var bytes := zip.read_file("xl/sharedStrings.xml")
	if bytes.is_empty():
		return strings
	var parser := XMLParser.new()
	if parser.open_buffer(bytes) != OK:
		return strings
	var current := ""
	var in_item := false
	while parser.read() == OK:
		var type := parser.get_node_type()
		if type == XMLParser.NODE_ELEMENT:
			if parser.get_node_name() == "si":
				in_item = true
				current = ""
		elif type == XMLParser.NODE_TEXT:
			if in_item:
				current += parser.get_node_data()
		elif type == XMLParser.NODE_ELEMENT_END:
			if parser.get_node_name() == "si" and in_item:
				strings.append(_decode(current))
				in_item = false
	return strings


# ---------------------------------------------------------------- 工作表

static func _read_sheet(bytes: PackedByteArray, shared: PackedStringArray) -> Array:
	var rows := []
	var parser := XMLParser.new()
	if parser.open_buffer(bytes) != OK:
		return rows
	var row := []
	var in_cell := false
	var in_value := false
	var cell_ref := ""
	var cell_type := ""
	var cell_text := ""
	while parser.read() == OK:
		var type := parser.get_node_type()
		if type == XMLParser.NODE_ELEMENT:
			var node := parser.get_node_name()
			if node == "row":
				row = []
			elif node == "c":
				in_cell = true
				in_value = false
				cell_ref = _attr(parser, "r")
				cell_type = _attr(parser, "t")
				cell_text = ""
			elif node == "v" or node == "t":
				in_value = true
		elif type == XMLParser.NODE_TEXT:
			if in_cell and in_value:
				cell_text += parser.get_node_data()
		elif type == XMLParser.NODE_ELEMENT_END:
			var node := parser.get_node_name()
			if node == "v" or node == "t":
				in_value = false
			elif node == "c":
				in_cell = false
				in_value = false
				var column := _column_index(cell_ref)
				while row.size() <= column:
					row.append("")
				row[column] = _cell_value(cell_type, cell_text, shared)
			elif node == "row":
				if not _is_blank_row(row):
					rows.append(row)
	return rows


static func _cell_value(cell_type: String, raw: String, shared: PackedStringArray) -> String:
	match cell_type:
		"s":
			var index := raw.strip_edges().to_int()
			if index >= 0 and index < shared.size():
				return shared[index]
			return ""
		"inlineStr", "str":
			return _decode(raw)
		"b":
			return "TRUE" if raw.strip_edges() == "1" else "FALSE"
		_:
			return raw.strip_edges()


static func _is_blank_row(row: Array) -> bool:
	for value in row:
		if String(value).strip_edges() != "":
			return false
	return true


static func _column_index(ref: String) -> int:
	var index := 0
	var found := false
	for i in ref.length():
		var code := ref.unicode_at(i)
		if code >= 65 and code <= 90:
			index = index * 26 + (code - 64)
			found = true
		elif code >= 97 and code <= 122:
			index = index * 26 + (code - 96)
			found = true
		else:
			break
	return index - 1 if found else 0


static func _attr(parser: XMLParser, name: String) -> String:
	for i in parser.get_attribute_count():
		var attr_name := parser.get_attribute_name(i)
		if attr_name == name or attr_name.ends_with(":" + name):
			return parser.get_attribute_value(i)
	return ""


## 把 XML 实体（含 Excel 常见的 &#21345; 数字引用）还原成字符。
static func _decode(text: String) -> String:
	if not text.contains("&"):
		return text
	var result := text
	result = result.replace("&lt;", "<")
	result = result.replace("&gt;", ">")
	result = result.replace("&quot;", "\"")
	result = result.replace("&apos;", "'")
	result = result.replace("&amp;", "&")
	var regex := RegEx.new()
	regex.compile("&#(x?[0-9A-Fa-f]+);")
	for m in regex.search_all(result):
		var raw := m.get_string(1)
		var code := raw.substr(1).hex_to_int() if raw.begins_with("x") else raw.to_int()
		if code > 0:
			result = result.replace(m.get_string(0), String.chr(code))
	return result
