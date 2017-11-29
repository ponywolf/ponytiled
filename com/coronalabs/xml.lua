--module(..., package.seeall)

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
--
-- xml.lua - XML parser for use with the Corona SDK.
--
-- version: 1.0
--
-- NOTE: This is a modified version of Alexander Makeev's Lua-only XML parser
-- found here: http://lua-users.org/wiki/LuaXml
--
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
local M={}
function M.newParser()

	local DEBUG = false

	local XmlParser = {}

	function XmlParser:ToXmlString(value)
		value = string.gsub (value, "&", "&amp;")   -- '&' -> "&amp;"
		value = string.gsub (value, "<", "&lt;")   -- '<' -> "&lt;"
		value = string.gsub (value, ">", "&gt;")    -- '>' -> "&gt;"
		--value = string.gsub (value, "'", "&apos;")  -- '\'' -> "&apos;"
		value = string.gsub (value, "\"", "&quot;")  -- '"' -> "&quot;"
		-- replace non printable char -> "&#xD;"
		value = string.gsub(value, "([^%w%&%;%p%\t% ])",
			function (c) 
				return string.format("&#x%X;", string.byte(c)) 
				--return string.format("&#x%02X;", string.byte(c)) 
				--return string.format("&#%02d;", string.byte(c)) 
			end);
		return value
	end

	function XmlParser:FromXmlString(value)  
		value = string.gsub(value, "&#x([%x]+)%;",
			function(h) 
				return string.char(tonumber(h,16)) 
			end)
		value = string.gsub(value, "&#([0-9]+)%;",
			function(h)
				--
				-- hack to deal with UTF-8 entities
				-- 
				if h == "8217" or h == "8216" or h == "8218" then return "'" end
				if h == "8211" then return "-" end
				if h == "8212" then return "--" end
				if h == "8230" then return "..." end
				if h == "8220" or h == "8221" or h == "8222" then return "\"" end
				if h == "8214" then return "(tm)" end
				if h == "8226" then return "." end
				if tonumber(h) >= 1000 then return "" end
				return string.char(tonumber(h,10)) 
			end);
		value = string.gsub (value, "&quot;", "\"")
		value = string.gsub (value, "&apos;", "'")
		value = string.gsub (value, "&gt;", ">")
		value = string.gsub (value, "&lt;", "<")
		value = string.gsub (value, "&amp;", "&")
		return value;
	end

	function XmlParser:ParseArgs(s)
		local arg = {}
		string.gsub(s, "(%w+)=([\"'])(.-)%2", function (w, _, a)
				arg[w] = self:FromXmlString(a)
			end)
		return arg
	end

	function log(...)
		if DEBUG then
			print("XmlParser: ", unpack(arg))
		end
	end

	function XmlParser:ParseXmlText(xmlText)    
		local stack = {}
		local top = {name=nil,value=nil,properties={},child={}}
		table.insert(stack, top)
		local ni,c,label,xarg, empty,cdata_end,cdata_end2,abs
		local i, j = 1, 1
		while true do      
			ni, j, c, label, xarg, empty = 
			xmlText:find("<(%/?)([%w:]+)(.-)(%/?)>", i)                        
			if not ni then break end    

			local text = string.sub(xmlText, i, ni-1)         

			local cdata_start,cdata_start2 = text:find("<!%[CDATA%[")        
			if (cdata_start) then
				abs = i+cdata_start2       
				log("Found CDATA start tag", abs)        
				cdata_end, cdata_end2 = xmlText:find("%]%]>",i)
				log("Found CDATA end tag", cdata_end2)      
				i = cdata_end2+1
			else 
				i = j+1
			end

			if not cdata_start and not string.find(text, "^%s*$") then -- skip white space           
				top.value=(top.value or "")..self:FromXmlString(text)      
			end

			if cdata_start then -- CDATA 
				top.value = (top.value or "")..xmlText:sub(abs,cdata_end-1)
			elseif empty == "/" then  -- empty element tag
				table.insert(top.child, {name=label,value=nil,properties=self:ParseArgs(xarg),child={}})
			elseif c == "" then   -- start tag
				top = {name=label, value=nil, properties=self:ParseArgs(xarg), child={}}
				table.insert(stack, top)   -- new level
				log("openTag ="..top.name)
			else  -- end tag
				local toclose = table.remove(stack)  -- remove top
				log("closeTag="..toclose.name)
				top = stack[#stack]
				if #stack < 1 then
					error("XmlParser: nothing to close with "..label)
				end
				if toclose.name ~= label then        
					error("XmlParser: trying to close <"..toclose.name.."> with <"..label..">")
				end
				table.insert(top.child, toclose)
			end  

		end
		local text = string.sub(xmlText, i)
		if not string.find(text, "^%s*$") then
			stack[#stack].value=(stack[#stack].value or "")..self:FromXmlString(text)
		end
		if #stack > 1 then
			error("XmlParser: unclosed "..stack[stack.n].name)
		end  

		--local xml_obj = XmlObject(stack[1].child[1])

		return stack[1].child[1]
	end

	function XmlParser:loadFile(xmlFilename, base)

		if not base then
			base = system.ResourceDirectory
		end

		local path = system.pathForFile( xmlFilename, base )
		local hFile, err = io.open(path,"r")

		if hFile and not err then
			local xmlText=hFile:read("*a") -- read file content
			io.close(hFile)
			return self:ParseXmlText(xmlText),nil
		else
			print( err )
			return nil
		end
	end

	return XmlParser
end

return M