--
-- tests/actions/vstudio/vc200x/test_external_compiler.lua
-- Validate generation the VCCLLinker element for external tools in VS 200x C/C++ projects.
-- Copyright (c) 2009-2012 Jason Perkins and the Premake project
--
	T.vs200x_external_linker = { }
	local suite = T.vs200x_external_linker
	local vc200x = premake.vstudio.vc200x


--
-- Setup/teardown
--

	local sln, prj

	function suite.setup()
		_ACTION = "vs2008"
		sln, prj = test.createsolution()
		kind "ConsoleApp"
		system "PS3"
	end

	local function prepare()
		local cfg = premake.project.getconfig(prj, "Debug")
		vc200x.VCLinkerTool(cfg)
	end


--
-- Verify the basic structure of a PS3 executable, with no extra
-- flags or settings.
--

	function suite.looksGood_onPS3ConsoleApp()
		kind "ConsoleApp"
		prepare()
		test.capture [[
			<Tool
				Name="VCLinkerTool"
				AdditionalOptions="-s"
				OutputFile="$(OutDir)\MyProject.elf"
				LinkIncremental="0"
				GenerateManifest="false"
				ProgramDatabaseFile=""
				RandomizedBaseAddress="1"
				DataExecutionPrevention="0"
			/>
		]]
	end


--
-- Verify the structure of a PS3 static library.
--

	function suite.looksGood_onPS3StaticLib()
		kind "StaticLib"
		prepare()
		test.capture [[
			<Tool
				Name="VCLibrarianTool"
				AdditionalOptions="-s"
				OutputFile="$(OutDir)\libMyProject.a"
			/>
		]]
	end


--
-- Verify the handling of system libraries.
--

	function suite.additionalDependencies_onSystemLibs()
		links { "fs_stub", "net_stub" }
		prepare()
		test.capture [[
			<Tool
				Name="VCLinkerTool"
				AdditionalOptions="-s"
				AdditionalDependencies="-lfs_stub -lnet_stub"
		]]
	end


--
-- Sibling dependencies should not appear in the list of links;
-- Visual Studio will add those automatically.
--

	function suite.excludesSiblings()
		links { "MyProject2" }
		project ("MyProject2")
		system "PS3"
		kind "StaticLib"
		language "C++"
		prepare()
		test.capture [[
			<Tool
				Name="VCLinkerTool"
				AdditionalOptions="-s"
				OutputFile="$(OutDir)\MyProject.elf"
		]]
	end



--
-- Sibling dependencies should appear in the list of links if
-- the NoImplicitLinks flag is set.
--

	function suite.includesSiblings_onNoExplicitLink()
		flags { "NoImplicitLink" }
		links { "MyProject2" }
		project ("MyProject2")
		system "PS3"
		kind "StaticLib"
		language "C++"
		prepare()
		test.capture [[
			<Tool
				Name="VCLinkerTool"
				AdditionalOptions="-s"
				AdditionalDependencies="libMyProject2.a"
		]]
	end
