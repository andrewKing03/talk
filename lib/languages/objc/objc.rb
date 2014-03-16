def make_source
  @prefix = common_class_prefix if meta(:namespace) == "true"
  master_files = [ "TalkClasses.h", "TalkClassesForward.h", "TalkConstants.h", "TalkObjectList.h"]
  master_files.each { |template| generate_template(template) }

  @base[:class].each do |cls|
    @current_class = cls
    @current_class[:field] ||= []
    file_base = filename_for_class(cls)
    [".h", ".m"].each { |ext| generate_template(file_base+ext, "class"+ext+".erb") }
  end
end

def filename_for_class(cls)
  if meta(:namespace) == "true" then
    namespace = cls[:name][@prefix.length..-1].split(".")[0..-2]
    return truncated_name(cls) if namespace.empty?

    namespace = namespace[1..-1] while namespace[0].length == 0
    return File.join(namespace.join("/"), truncated_name(cls))
  end

  truncated_name(cls)
end

def autogenerated_warning
  <<-AUTOGEN_DONE
// Autogenerated from Talk
// Please do not edit this file directly. Instead, modify the underlying .talk files.
  AUTOGEN_DONE
end

def truncated_name(name)
  name = name[:name] if name.is_a? Hash
  name.split('.').last
end

def wrap_text_to_width(text, width=80, preamble="")
  width -= preamble.length
  words = text.split(/\s+/)
  lines = []

  words.each do |word|
    if lines.empty? or (lines.last + " " + word).length >= width then
      lines.push (preamble + word)
    else
      lines.last << " " + word
    end
  end

  lines.empty? ? "" : lines.join("\n")
end

def glossary_term_name(name)
  "k"+name
end

def constant_definition(constant)
  "#{constant[:name]} = #{constant[:value].to_i}, #{comment_line(constant)}"
end

def comment_line(tag)
  tag[:description].nil? ? "" : "//!< #{tag[:description]}"
end

def comment_block(tag, indent_level=0)
  lines = []
  indent = "\t" * indent_level
  lines.push(indent + "/*!")
  lines.push(wrap_text_to_width(tag[:description], 80, indent + " *  ")) unless tag[:description].nil?
  lines.push(indent + " *  ")
  lines.push(indent + " *  " + definition_reference(tag))
  lines.push(indent + " */")

  lines.join("\n")
end

def definition_reference(tag)
  "@talkFile #{tag[:__meta][:file]}:#{tag[:__meta][:line]}"
end

def superclass(cls)
  cls[:inherits].nil? ? "TalkObject" : cls[:inherits]
end

def is_native?(type)
  type != "talkobject" and is_primitive?(type)
end

def is_array?(type)
  type == "[]"
end

def is_dict?(type)
  type == "{}"
end

def mapped_name(container_name, object_name, type, name_key=:name)
  object_name = object_name[:name] if object_name.is_a? Hash
  container_name = container_name[:name] if container_name.is_a? Hash

  @target[:map].each do |map|
    matches = (map[:type] == type.to_s && map[:class_name] == container_name && map[:field_name] == object_name)
    return map[:new_field_name] if matches
  end

  object_name
end

def assist_line(field)
  return nil if field[:type].length <= 1
  elements = []
  field[:type].reverse.each do |type|
    elements.push case
      when is_array?(type)
        "array"
      when is_dict?(type)
        "dict"
      when type == "talkobject"
        "TalkObject"
      when is_native?(type)
        "native"
      else
        truncated_name(type)
    end
  end

  elements.join(".")
end

def dynamic_body_for_named_wrapper
  return "@dynamic body" if truncated_name(@current_class) == 'NamedObjectWrapper'
  ""
end

def primitive_type(unsigned, size)
  type = "int#{size}_t"
  type = "u" + type if unsigned
  type
end

def field_definition(cls, field)
  base_type = field[:type].last
  objc_type = case
    when is_array?(base_type)
      "NSMutableArray *"
    when is_dict?(base_type)
      "NSMutableDictionary *"
    when (base_type == "talkobject" or base_type == "object")
      "TalkObject *"
    when base_type.match(/(u)?int(8|16|32|64)/)
      primitive_type(not($1.nil?), $2)
    when base_type == "real"
      "double"
    when base_type == "bool"
      "BOOL"
    when base_type == "string"
      "NSString *"
    else
      truncated_name(base_type) + " *"
  end
  "#{objc_type} #{mapped_name(cls, field, :field)}"
end
