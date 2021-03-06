--
-- solution.lua
-- Work with the list of solutions loaded from the script.
-- Copyright (c) 2002-2013 Jason Perkins and the Premake project
--

	premake.solution = { }
	local solution = premake.solution
	local project = premake.project
	local configset = premake.configset
	local context = premake.context
	local tree = premake.tree


-- The list of defined solutions (which contain projects, etc.)

	premake.solution.list = { }


--
-- Create a new solution and add it to the session.
--
-- @param name
--    The new solution's name.
-- @return
--    A new solution object.
--

	function solution.new(name)
		local sln = {}

		-- add to master list keyed by both name and index
		table.insert(premake.solution.list, sln)
		premake.solution.list[name] = sln

		sln.name = name
		sln.blocks = {}
		sln.projects = {}

		local cset = configset.new(configset.root)
		cset.basedir = os.getcwd()
		cset.filename = name
		sln.configset = cset

		-- attach a type descriptor
		setmetatable(sln, {
			__type = "solution",
			__index = function(sln, key)
				return sln.configset[key]
			end,
		})

		return sln
	end


--
-- Add a new project to the solution.
--
-- @param sln
--    The solution to contain the project.
-- @param prj
--    The new project object.
--

	function solution.addproject(sln, prj)
		-- add keyed by array index AND name
		table.insert(sln.projects, prj)
		sln.projects[prj.name] = prj
	end


--
-- Creates a new project, which the given
--
-- Iterates through all of the current solutions, bakes down their contents,
-- and then replaces the original solution object with this baked result.
-- This is the entry point to the whole baking process, which happens after
-- the scripts have run, but before the project files are generated.
--

	function solution.bakeall()
		local result = {}
		for i, sln in ipairs(solution.list) do
			result[i] = solution.bake(sln)
		end
		solution.list = result
	end


--
-- Prepare the solution information received from the project script
-- for project generation.
--
-- @param sln
--    The solution to be baked.
-- @return
--    The baked version of the solution.
--

	function solution.bake(sln)

		-- Wrap the solution's configuration set (which contains all of the information
		-- provided by the project script) with a context object. The context handles
		-- the expansion of tokens, and caching of retrieved values. The environment
		-- values are used when expanding tokens.

		local environ = {
			sln = sln,
		}

		local ctx = context.new(sln.configset, environ)

		ctx.name = sln.name
		ctx.baked = true

		-- Add filtering terms to the context and then compile the results. These
		-- terms describe the "operating environment"; only results contained by
		-- configuration blocks which match these terms will be returned.

		context.addterms(ctx, _ACTION)
		context.compile(ctx)

		-- Specify the solution's file system location; when path tokens are
		-- expanded in solution values, they will be made relative to this.

		ctx.location = ctx.location or sln.basedir
		context.basedir(ctx, ctx.location)

		-- Now bake down all of the projects contained in the solution, and
		-- store that for future reference

		local projects = {}
		for i, prj in ipairs(sln.projects) do
			projects[i] = project.bake(prj, ctx)
			projects[prj.name] = projects[i]
		end

		ctx.projects = projects

		-- Synthesize a default solution file output location

		ctx.location = ctx.location or sln.basedir

		-- I now have enough information to assign unique object directories
		-- to each project configuration in the solution.

		solution.bakeobjdirs(ctx)

		-- Build a master list of configuration/platform pairs from all of the
		-- projects contained by the solution; I will need this when generating
		-- solution files in order to provide a map from solution configurations
		-- to project configurations.

		ctx.configs = solution.bakeconfigs(ctx)

		return ctx

	end


--
-- Create a list of solution-level build configuration/platform pairs.
--

	function solution.bakeconfigs(sln)
		local buildcfgs = sln.configurations or {}
		local platforms = sln.platforms or {}

		local configs = {}
		for _, buildcfg in ipairs(buildcfgs) do
			if #platforms > 0 then
				for _, platform in ipairs(platforms) do
					table.insert(configs, { ["buildcfg"] = buildcfg, ["platform"] = platform })
				end
			else
				table.insert(configs, { ["buildcfg"] = buildcfg })
			end
		end

		-- fill in any calculated values
		for _, cfg in ipairs(configs) do
			cfg.solution = sln
			premake.config.bake(cfg)
		end

		return configs
	end


--
-- Assigns a unique objects directory to every configuration of every project
-- in the solution, taking any objdir settings into account, to ensure builds
-- from different configurations won't step on each others' object files.
-- The path is built from these choices, in order:
--
--   [1] -> the objects directory as set in the config
--   [2] -> [1] + the platform name
--   [3] -> [2] + the build configuration name
--   [4] -> [3] + the project name
--

	function solution.bakeobjdirs(sln)
		-- function to compute the four options for a specific configuration
		local function getobjdirs(cfg)
			local dirs = {}

			local dir = path.getabsolute(path.join(cfg.project.location, cfg.objdir or "obj"))
			table.insert(dirs, dir)

			if cfg.platform then
				dir = path.join(dir, cfg.platform)
				table.insert(dirs, dir)
			end

			dir = path.join(dir, cfg.buildcfg)
			table.insert(dirs, dir)

			dir = path.join(dir, cfg.project.name)
			table.insert(dirs, dir)

			return dirs
		end

		-- walk all of the configs in the solution, and count the number of
		-- times each obj dir gets used
		local counts = {}
		local configs = {}

		for prj in premake.solution.eachproject(sln) do
			for cfg in project.eachconfig(prj) do
				-- get the dirs for this config, and remember the association
				local dirs = getobjdirs(cfg)
				configs[cfg] = dirs

				for _, dir in ipairs(dirs) do
					counts[dir] = (counts[dir] or 0) + 1
				end
			end
		end

		-- now walk the list again, and assign the first unique value
		for cfg, dirs in pairs(configs) do
			for _, dir in ipairs(dirs) do
				if counts[dir] == 1 then
					cfg.objdir = dir
					break
				end
			end
		end
	end


--
-- Iterate over the collection of solutions in a session.
--
-- @returns
--    An iterator function.
--

	function solution.each()
		local i = 0
		return function ()
			i = i + 1
			if i <= #premake.solution.list then
				return premake.solution.list[i]
			end
		end
	end


--
-- Iterate over the configurations of a solution.
--
-- @param sln
--    The solution to query.
-- @return
--    A configuration iteration function.
--

	function solution.eachconfig(sln)
		-- to make testing a little easier, allow this function to
		-- accept an unbaked solution, and fix it on the fly
		if not sln.baked then
			sln = solution.bake(sln)
		end

		local i = 0
		return function()
			i = i + 1
			if i > #sln.configs then
				return nil
			else
				return sln.configs[i]
			end
		end
	end


--
-- Iterate over the projects of a solution (next-gen).
--
-- @param sln
--    The solution.
-- @return
--    An iterator function, returning project configurations.
--

	function solution.eachproject(sln)
		local i = 0
		return function ()
			i = i + 1
			if i <= #sln.projects then
				return premake.solution.getproject(sln, i)
			end
		end
	end


--
-- Locate a project by name, case insensitive.
--
-- @param sln
--    The solution to query.
-- @param name
--    The name of the projec to find.
-- @return
--    The project object, or nil if a matching project could not be found.
--

	function solution.findproject(sln, name)
		name = name:lower()
		for _, prj in ipairs(sln.projects) do
			if name == prj.name:lower() then
				return prj
			end
		end
		return nil
	end


--
-- Retrieve a solution by name or index.
--
-- @param key
--    The solution key, either a string name or integer index.
-- @returns
--    The solution with the provided key.
--

	function solution.get(key)
		return premake.solution.list[key]
	end


--
-- Returns the file name for this solution.
--
-- @param sln
--    The solution object to query.
-- @param ext
--    An optional file extension to add, with the leading dot.
-- @return
--    The absolute path to the solution's file.
--


	solution.getfilename = project.getfilename


--
-- Retrieve the tree of project groups.
--
-- @param sln
--    The solution to query.
-- @return
--    The tree of project groups defined for the solution.
--

	function solution.grouptree(sln)
		-- check for a previously cached tree
		if sln.grouptree then
			return sln.grouptree
		end

		-- build the tree of groups

		local tr = tree.new()
		for prj in solution.eachproject(sln) do
			local prjpath = path.join(prj.group, prj.name)
			local node = tree.add(tr, prjpath)
			node.project = prj
		end

		-- assign UUIDs to each node in the tree
		tree.traverse(tr, {
			onnode = function(node)
				node.uuid = os.uuid(node.path)
			end
		})

		sln.grouptree = tr
		return tr
	end


--
-- Retrieve the project configuration at a particular index.
--
-- @param sln
--    The solution.
-- @param idx
--    An index into the array of projects.
-- @return
--    The project configuration at the given index.
--

	function solution.getproject(sln, idx)
		-- to make testing a little easier, allow this function to
		-- accept an unbaked solution, and fix it on the fly
		if not sln.baked then
			sln = solution.bake(sln)
		end
		return sln.projects[idx]
	end


--
-- Checks to see if any projects contained by a solution use
-- a C or C++ as their language.
--
-- @param sln
--    The solution to query.
-- @return
--    True if at least one project in the solution uses C or C++.
--

	function solution.hascppproject(sln)
		for prj in solution.eachproject(sln) do
			if project.iscpp(prj) then
				return true
			end
		end
		return false
	end


--
-- Checks to see if any projects contained by a solution use
-- a .NET language.
--
-- @param sln
--    The solution to query.
-- @return
--    True if at least one project in the solution uses a
--    .NET language
--

	function solution.hasdotnetproject(sln)
		for prj in solution.eachproject(sln) do
			if project.isdotnet(prj) then
				return true
			end
		end
		return false
	end


