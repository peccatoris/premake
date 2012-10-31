--
-- _manifest.lua
-- Manage the list of built-in Premake scripts.
-- Copyright (c) 2002-2012 Jason Perkins and the Premake project
--

-- The master list of built-in scripts. Order is important! If you want to
-- build a new script into Premake, add it to this list.

	return
	{
		-- Lua extensions
		"base/os.lua",
		"base/path.lua",
		"base/string.lua",
		"base/table.lua",
		
		-- core files
		"base/io.lua",
		"base/globals.lua",
		"base/action.lua",
		"base/criteria.lua",
		"base/option.lua",
		"base/tree.lua",
		"base/project.lua",
		"base/config.lua",
		"base/bake.lua",
		"base/validate.lua",
		"base/help.lua",
		"base/premake.lua",
		
		-- configuration APIs
		"base/configset.lua",
		"base/context.lua",
		"base/api.lua",
		
		-- runtime environment setup
		"_premake_init.lua",
		"base/cmdline.lua",
		
		-- project APIs
		"project/oven.lua",
		"project/project.lua",
		"project/config.lua",
		"base/solution.lua",

		-- tool APIs
		"tools/dotnet.lua",
		"tools/gcc.lua",
		"tools/msc.lua",
		"tools/ow.lua",
		"tools/snc.lua",

		-- CodeBlocks action
		"actions/codeblocks/_codeblocks.lua",
		"actions/codeblocks/codeblocks_workspace.lua",
		"actions/codeblocks/codeblocks_cbp.lua",
		
		-- CodeLite action
		"actions/codelite/_codelite.lua",
		"actions/codelite/codelite_workspace.lua",
		"actions/codelite/codelite_project.lua",
		
		-- GNU make action
		"actions/make/_make.lua",
		"actions/make/make_solution.lua",
		"actions/make/make_cpp.lua",
		"actions/make/make_csharp.lua",
		
		-- Visual Studio actions
		"actions/vstudio/_vstudio.lua",
		"actions/vstudio/vs2002_solution.lua",
		"actions/vstudio/vs2002_csproj.lua",
		"actions/vstudio/vs2002_csproj_user.lua",
		"actions/vstudio/vs200x_vcproj.lua",
		"actions/vstudio/vs200x_vcproj_user.lua",
		"actions/vstudio/vs2003_solution.lua",
		"actions/vstudio/vs2005_solution.lua",
		"actions/vstudio/vs2005_csproj.lua",
		"actions/vstudio/vs2005_csproj_user.lua",
		"actions/vstudio/vs2010_vcxproj.lua",
		"actions/vstudio/vs2010_vcxproj_user.lua",
		"actions/vstudio/vs2010_vcxproj_filters.lua",
	
		-- Xcode action
		"actions/xcode/_xcode.lua",
		"actions/xcode/xcode_common.lua",
		"actions/xcode/xcode_project.lua",
		
		-- Xcode4 action
		"actions/xcode/xcode4_workspace.lua",
		
		-- Clean action
		"actions/clean/_clean.lua",
	}
