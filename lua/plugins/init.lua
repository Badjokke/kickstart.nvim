local function load_dir(base_module, dir_path)
	for name, ftype in vim.fs.dir(dir_path) do
		if name ~= "init.lua" then
			if ftype == "file" and name:match("%.lua$") then
				local module = base_module .. "." .. name:gsub("%.lua$", "")
				local ok, err = pcall(require, module)
				if not ok then
					vim.notify("Error loading " .. module .. ": " .. err, vim.log.levels.ERROR)
				end
			elseif ftype == "directory" then
				local sub_path = dir_path .. "/" .. name
				for sub_name, sub_ftype in vim.fs.dir(sub_path) do
					if sub_ftype == "file" and sub_name:match("%.lua$") then
						local module = base_module .. "." .. name .. "." .. sub_name:gsub("%.lua$", "")
						local ok, err = pcall(require, module)
						if not ok then
							vim.notify("Error loading " .. module .. ": " .. err, vim.log.levels.ERROR)
						end
					end
				end
			end
		end
	end
end
load_dir("plugins", vim.fn.stdpath("config") .. "/lua/plugins")
