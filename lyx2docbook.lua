#!/usr/bin/env lua

local args = {...}

local docbook_xml_preamble = [[<?xml version="1.0" encoding="UTF-8"?>
      <?xml-model href="http://www.docbook.org/xml/5.0/rng/docbookxi.rng"
    schematypens="http://relaxng.org/ns/structure/1.0"?>
<article version="5.0" xml:id="luarocks" xml:lang="fr"
         xmlns="http://docbook.org/ns/docbook"
         xmlns:xlink="http://www.w3.org/1999/xlink"
         xmlns:xi="http://www.w3.org/2001/XInclude"
         xmlns:ns6="http://www.w3.org/1999/xhtml"
         xmlns:ns5="http://www.w3.org/2000/svg"
         xmlns:ns3="http://www.w3.org/1998/Math/MathML"
         xmlns:ns="http://docbook.org/ns/docbook">]]

local outfile = args[1]:gsub(".lyx$", ".xml")

local function run(cmd)
   local code = os.execute(cmd)
   return code == 0 or code == true
end

if run("[ -e '"..outfile.."~' ]") then
   error("Backup file "..outfile.."~ exists. Aborting.")
end
if not run("cp '"..outfile.."' '"..outfile.."~'") then
   error("Failed creating backup file "..outfile.."~. Aborting.")
end

local fdlyx = io.open(args[1])
local fdxml = io.open(outfile, "w")

local function tag(name)
   fdxml:write("<"..name..">\n")
end

local function tag_nb(name)
   fdxml:write("<"..name..">")
end

local layouts = {}

local function push_layout(open, close)
   if open then
      tag_nb(open)
      if not close then
         close = "/" .. open
      end
      table.insert(layouts, close)
   else
      table.insert(layouts, "")
   end
end

local function pop_layout()
   local close = table.remove(layouts, #layouts)
   if close ~= "" then
      tag(close)
   end
end

local section = 0
local subsection = 0
local skip_lines = 0
local in_lyx_code = false
local in_inset_args = false
local inset_tags = {}
local new_depth = true

local lists = {}

local function push_list(open, close)
   tag(open)
   table.insert(lists, close)
end

local function pop_list()
   local close = table.remove(lists, #lists)
   tag(close)
end

local function push_inset(name)
   if name ~= "" then
      tag_nb(name)
   end
   table.insert(inset_tags, name)
end

local function pop_inset()
   if #inset_tags > 0 then
      local itag = table.remove(inset_tags, #inset_tags)
      if itag ~= "" then
         tag_nb("/"..itag)
      end
   end
end

local list_for = {
   Itemize = "itemizedlist",
   Enumerate = "orderedlist",
}

for line in fdlyx:lines() do

   if line == "\\lyxformat 474" then
      print("LyX format supported. Will perform conversion.")

   elseif line:match("^#LyX ") then -- ignore

   elseif line:match("^\\lyxformat ") then
      error("Unsupported LyX format.")

   elseif line == "\\begin_document" then
      fdxml:write(docbook_xml_preamble)

   elseif line == "\\end_document" then -- ignore

   elseif line == "\\begin_header" then -- ignore
   
   elseif line == "\\begin_body" then -- ignore

   elseif line == "\\textclass extarticle" then
      print("Text class supported. Will continue...")

   elseif line:match("\\use_default_options ")
       or line:match("\\maintain_unincl")
       or line:match("\\language")
       or line:match("\\inputenc")
       or line:match("\\fontenc")
       or line:match("\\font_")
       or line:match("\\use_")
       or line:match("\\graphics")
       or line:match("\\default_output")
       or line:match("\\output_")
       or line:match("\\bibtex")
       or line:match("\\index_")
       or line:match("\\paper")
       or line:match("\\spacing")
       or line:match("\\cite")
       or line:match("\\biblio")
       or line:match("\\suppress_date")
       or line:match("\\justification")
       or line:match("\\index")
       or line:match("\\shortcut")
       or line:match("\\color")
       or line:match("\\end_index")
       or line:match("\\[a-z]*margin")
       or line:match("\\[a-z]*depth")
       or line:match("\\paragraph")
       or line:match("\\quotes")
       or line:match("\\tracking")
       or line:match("\\html")
    then
      print("Ignoring directive: "..line)
   
   elseif line:match("^\\begin_layout ") then
      in_inset_args = false

      if line == "\\begin_layout LyX-Code" then
         if not in_lyx_code then
            tag_nb("programlisting")
            in_lyx_code = true
         end
         push_layout()

      else
         if in_lyx_code then
            tag("/programlisting")
            in_lyx_code = false
         end
         
         local next_layout = line:match("\\begin_layout (.*)")
         if #lists > 0 and lists[#lists] ~= list_for[next_layout] then
            pop_list()
            new_depth = true
         end

         if line == "\\begin_layout Title" then
            push_layout("title")
      
         elseif line == "\\begin_layout Abstract" then
            push_layout("info><abstract><para", "/para></abstract></info")
      
         elseif line == "\\begin_layout Standard" then
            push_layout("para")
      
         elseif line == "\\begin_layout Section" then
            if subsection > 0 then
               tag("/subsection")
            end
            if section > 0 then
               tag("/section")
            end
            section = section + 1
            tag("section")
            subsection = 0
            push_layout("title")
      
         elseif line == "\\begin_layout Subsection" then
            if subsection > 0 then
               tag("/subsection")
            end
            subsection = subsection + 1
            tag("subsection")
            push_layout("title")

         elseif list_for[next_layout] then
            local list_tag = list_for[next_layout]
            if new_depth then
               tag(list_tag)
               push_list(list_tag)
               new_depth = false
            end
            push_layout("listitem")
      
         elseif line == "\\begin_layout Plain Layout" then
            push_layout()

         else
            error("Unknown layout command "..line)
         end
      end

   elseif line == "\\family typewriter" then
      push_layout(not in_lyx_code and "code" or nil)

   elseif line == "\\family default" then
      pop_layout()

   elseif line:match("^\\begin_deeper") then
      new_depth = true

   elseif line:match("^\\end_deeper") then
      new_depth = false
      pop_list()
      
   elseif line:match("^\\begin_inset ") then
      in_inset_args = true

      if line == "\\begin_inset Quotes eld" then
         fdxml:write("“")
         push_inset("")
      
      elseif line == "\\begin_inset Quotes erd" then
         fdxml:write("”")
         push_inset("")

      elseif line == "\\begin_inset Flex URL" then
         push_inset("code")

      elseif line == "\\begin_inset Foot" then
         push_inset("footnote")

      elseif line == "\\begin_inset Float figure" then
         push_inset("figure")

      elseif line == "\\begin_inset Caption Standard" then
         push_inset("caption")

      elseif line == "\\begin_inset CommandInset label" then
         push_inset("")

      elseif line == "\\begin_inset CommandInset ref" then
         fdxml:write("<FIXME WITH A PROPER link>")
         push_inset("")

      elseif line == "\\begin_inset Newline newline" then
         push_inset("")
         
      else
         error("Unknown inset command "..line)
      end

   elseif line == "\\end_header" then
      skip_lines = 1

   elseif line == "\\end_inset" then
      in_inset_args = false
      skip_lines = 1
      pop_inset()

   elseif line == "\\end_layout" then
      if not in_lyx_code then
         pop_layout()
      else
         fdxml:write("\n")
      end

   elseif line == "\\end_body" then
      if in_lyx_code then
         tag("/programlisting")
      end
      while #lists > 0 do
         pop_list()
      end
      while #layouts > 0 do
         pop_layout()
      end
      if subsection > 0 then
         tag("/subsection")
      end
      if section > 0 then
         tag("/section")
      end

   elseif line == "\\emph on" then
      tag_nb("emphasis")

   elseif line:match("^\\size ") then -- ignore

   elseif line == "\\emph default" then
      tag_nb("/emphasis")

   elseif line == "\\backslash" then
      fdxml:write("\\")

   elseif line:match("^\\") then
      error("Unknown command "..line)
   else
      if skip_lines == 0 then
         if not in_inset_args then
            fdxml:write((line:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt:")))
         end
      else
         skip_lines = skip_lines - 1
      end
   end
end

print(outfile.." written.")

