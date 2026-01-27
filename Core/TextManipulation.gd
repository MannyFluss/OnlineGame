class_name TextManipulation


static func count_visible_chars(text: String) -> int:
	var visible_count = 0
	var in_tag = false

	for i in range(text.length()):
		if text[i] == '[':
			in_tag = true
		elif text[i] == ']':
			in_tag = false
		elif not in_tag:
			visible_count += 1

	return visible_count


static func build_display_with_n_chars(target_text: String, n: int) -> String:
	var result = ""
	var visible_count = 0
	var tag_stack = []
	var i = 0

	while i < target_text.length() and visible_count < n:
		if target_text[i] == '[':
			var tag_end = target_text.find(']', i)
			if tag_end != -1:
				var tag = target_text.substr(i, tag_end - i + 1)
				result += tag

				if tag.begins_with("[/"):
					if tag_stack.size() > 0:
						tag_stack.pop_back()
				else:
					tag_stack.push_back(tag)

				i = tag_end + 1
				continue

		result += target_text[i]
		visible_count += 1
		i += 1

	for j in range(tag_stack.size() - 1, -1, -1):
		var opening_tag = tag_stack[j]
		var tag_name = _extract_tag_name(opening_tag)
		result += "[/%s]" % tag_name

	return result


static func extract_tag_name(opening_tag: String) -> String:
	var content = opening_tag

	# Remove brackets if present
	if content.begins_with('[') and content.ends_with(']'):
		content = content.substr(1, content.length() - 2)

	# Find equals sign to separate tag name from arguments
	var equals_pos = content.find('=')
	if equals_pos != -1:
		# Extract tag name and trim trailing spaces
		return content.substr(0, equals_pos).strip_edges()

	# No arguments, just trim and return
	return content.strip_edges()

static func apply_tag_to_string(text: String, tag: String) -> String:
	if text.is_empty() or tag.is_empty():
		return text

	var closing_tag = "[/%s]" % _extract_tag_name("[%s]" % tag)
	var opening_tag = "[%s]" % tag

	return opening_tag + text + closing_tag

static func apply_tag_to_word(text: String, word: String, tag: String) -> String:
	if word.is_empty() or tag.is_empty():
		return text

	var closing_tag = "[/%s]" % _extract_tag_name("[%s]" % tag)
	var opening_tag = "[%s]" % tag

	var result = ""
	var search_pos = 0
	var word_pos = text.find(word, search_pos)

	while word_pos != -1:
		result += text.substr(search_pos, word_pos - search_pos)
		result += opening_tag
		result += text.substr(word_pos, word.length())
		result += closing_tag

		search_pos = word_pos + word.length()
		word_pos = text.find(word, search_pos)

	result += text.substr(search_pos)

	return result


static func _extract_tag_name(opening_tag: String) -> String:
	var content = opening_tag

	# Remove brackets if present
	if content.begins_with('[') and content.ends_with(']'):
		content = content.substr(1, content.length() - 2)

	# Find equals sign to separate tag name from arguments
	var equals_pos = content.find('=')
	if equals_pos != -1:
		# Extract tag name and trim trailing spaces
		return content.substr(0, equals_pos).strip_edges()

	# No arguments, just trim and return
	return content.strip_edges()
