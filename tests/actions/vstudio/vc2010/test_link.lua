--
-- tests/actions/vstudio/vc2010/test_link.lua
-- Validate linking and project references in Visual Studio 2010 C/C++ projects.
-- Copyright (c) 2011 Jason Perkins and the Premake project
--

	T.vstudio_vs2010_link = { }
	local suite = T.vstudio_vs2010_link
	local vc2010 = premake.vstudio.vc2010
	local project = premake5.project


--
-- Setup
--

	local sln, prj, cfg

	function suite.setup()
		_ACTION = "vs2010"
		sln, prj = test.createsolution()
		kind "SharedLib"
	end

	local function prepare(platform)
		cfg = project.getconfig(prj, "Debug", platform)
		vc2010.link(cfg)
	end


--
-- Check the basic element structure with default settings.
--

	function suite.defaultSettings()
		kind "SharedLib"
		prepare()
		test.capture [[
		<Link>
			<SubSystem>Windows</SubSystem>
			<GenerateDebugInformation>false</GenerateDebugInformation>
			<ImportLibrary>MyProject.lib</ImportLibrary>
		</Link>
		<ProjectReference>
			<LinkLibraryDependencies>false</LinkLibraryDependencies>
		</ProjectReference>
		]]
	end


--
-- Check the basic element structure with a release build.
--

	function suite.defaultSettings_onOptimize()
		flags "Optimize"
		prepare()
		test.capture [[
		<Link>
			<SubSystem>Windows</SubSystem>
			<GenerateDebugInformation>false</GenerateDebugInformation>
			<EnableCOMDATFolding>true</EnableCOMDATFolding>
			<OptimizeReferences>true</OptimizeReferences>
			<ImportLibrary>MyProject.lib</ImportLibrary>
		</Link>
		]]
	end


--
-- Check subsystem values with each project kind.
--

	function suite.subsystem_onConsoleApp()
		kind "ConsoleApp"
		prepare()
		test.capture [[
		<Link>
			<SubSystem>Console</SubSystem>
			<GenerateDebugInformation>false</GenerateDebugInformation>
			<EntryPointSymbol>mainCRTStartup</EntryPointSymbol>
		]]
	end

	function suite.subsystem_onWindowedApp()
		kind "WindowedApp"
		prepare()
		test.capture [[
		<Link>
			<SubSystem>Windows</SubSystem>
			<GenerateDebugInformation>false</GenerateDebugInformation>
			<EntryPointSymbol>mainCRTStartup</EntryPointSymbol>
		]]
	end

	function suite.subsystem_onSharedLib()
		kind "SharedLib"
		prepare()
		test.capture [[
		<Link>
			<SubSystem>Windows</SubSystem>
			<GenerateDebugInformation>false</GenerateDebugInformation>
			<ImportLibrary>MyProject.lib</ImportLibrary>
		</Link>
		]]
	end

	function suite.subsystem_onStaticLib()
		kind "StaticLib"
		prepare()
		test.capture [[
		<Link>
			<SubSystem>Windows</SubSystem>
			<GenerateDebugInformation>false</GenerateDebugInformation>
		</Link>
		]]
	end


--
-- Test the handling of the Symbols flag.
--

	function suite.generateDebugInfo_onSymbols()
		flags "Symbols"
		prepare()
		test.capture [[
		<Link>
			<SubSystem>Windows</SubSystem>
			<GenerateDebugInformation>true</GenerateDebugInformation>
		]]
	end


--
-- Any system libraries specified in links() should be listed as
-- additional dependencies.
--

	function suite.additionalDependencies_onSystemLinks()
		links { "lua", "zlib" }
		prepare()
		test.capture [[
		<Link>
			<SubSystem>Windows</SubSystem>
			<GenerateDebugInformation>false</GenerateDebugInformation>
			<AdditionalDependencies>lua.lib;zlib.lib;%(AdditionalDependencies)</AdditionalDependencies>
		]]
	end


--
-- Additional library directories should be specified, relative to the project.
--

	function suite.additionalLibraryDirectories_onLibDirs()
		libdirs { "../lib", "../lib64" }
		prepare()
		test.capture [[
		<Link>
			<SubSystem>Windows</SubSystem>
			<GenerateDebugInformation>false</GenerateDebugInformation>
			<AdditionalLibraryDirectories>..\lib;..\lib64;%(AdditionalLibraryDirectories)</AdditionalLibraryDirectories>
		]]
	end


--
-- Let to its own devices, VS will attempt to link against dependencies
-- that have been excluded from the build. To work around this, dependency
-- linking is turned off, and siblings are linked explicitly instead.
--

	function suite.includeSiblings_onOnlySiblingProjectLinks()
		links { "MyProject2" }
		test.createproject(sln)
		kind "SharedLib"
		prepare()
		test.capture [[
		<Link>
			<SubSystem>Windows</SubSystem>
			<GenerateDebugInformation>false</GenerateDebugInformation>
			<AdditionalDependencies>MyProject2.lib;%(AdditionalDependencies)</AdditionalDependencies>
		]]
	end

	function suite.includeSiblings_OnMixedLinks()
		links { "MyProject2", "kernel32" }
		test.createproject(sln)
		kind "SharedLib"
		prepare()
		test.capture [[
		<Link>
			<SubSystem>Windows</SubSystem>
			<GenerateDebugInformation>false</GenerateDebugInformation>
			<AdditionalDependencies>MyProject2.lib;kernel32.lib;%(AdditionalDependencies)</AdditionalDependencies>
		]]
	end

	function suite.excludeSibling_OnExcludedConfig()
		links { "MyProject2", "kernel32" }
		test.createproject(sln)
		kind "SharedLib"
		removeconfigurations { "Debug" }
		prepare()
		test.capture [[
		<Link>
			<SubSystem>Windows</SubSystem>
			<GenerateDebugInformation>false</GenerateDebugInformation>
			<AdditionalDependencies>kernel32.lib;%(AdditionalDependencies)</AdditionalDependencies>
		]]
	end


--
-- Static libraries do not link dependencies directly, to maintain
-- compatibility with GCC and others.
--

	function suite.additionalDependencies_onSystemLinksAndStaticLib()
		kind "StaticLib"
		links { "lua", "zlib" }
		libdirs { "../lib", "../lib64" }
		prepare()
		test.capture [[
		<Link>
			<SubSystem>Windows</SubSystem>
			<GenerateDebugInformation>false</GenerateDebugInformation>
		</Link>
		]]
	end


--
-- Check handling of the import library settings.
--

	function suite.importLibrary_onImpLibDir()
		implibdir "../lib"
		prepare()
		test.capture [[
		<Link>
			<SubSystem>Windows</SubSystem>
			<GenerateDebugInformation>false</GenerateDebugInformation>
			<ImportLibrary>..\lib\MyProject.lib</ImportLibrary>
		</Link>
		]]
	end



--
-- Check handling of additional options.
--

	function suite.additionalOptions_onNonStaticLib()
		kind "SharedLib"
		linkoptions { "/kupo" }
		prepare()
		test.capture [[
		<Link>
			<SubSystem>Windows</SubSystem>
			<GenerateDebugInformation>false</GenerateDebugInformation>
			<ImportLibrary>MyProject.lib</ImportLibrary>
			<AdditionalOptions>/kupo %(AdditionalOptions)</AdditionalOptions>
		]]
	end

	function suite.additionalOptions_onStaticLib()
		kind "StaticLib"
		linkoptions { "/kupo" }
		prepare()
		test.capture [[
		<Link>
			<SubSystem>Windows</SubSystem>
			<GenerateDebugInformation>false</GenerateDebugInformation>
		</Link>
		<Lib>
			<AdditionalOptions>/kupo %(AdditionalOptions)</AdditionalOptions>
		</Lib>
		]]
	end

 
--
-- Enable reference optimizing if Optimize flag is specified.
--

	function suite.optimizeReferences_onOptimizeFlag()
		flags { "Optimize" }
		prepare()
		test.capture [[
		<Link>
			<SubSystem>Windows</SubSystem>
			<GenerateDebugInformation>false</GenerateDebugInformation>
			<EnableCOMDATFolding>true</EnableCOMDATFolding>
			<OptimizeReferences>true</OptimizeReferences>
		]]
	end


--
-- On the PS3, system libraries must be prefixed with the "-l" flag.
--

	function suite.additionalDependencies_onPS3SystemLinks()
		system "PS3"
		links { "fs_stub", "net_stub" }
		prepare()
		test.capture [[
		<Link>
			<SubSystem>Windows</SubSystem>
			<GenerateDebugInformation>false</GenerateDebugInformation>
			<AdditionalDependencies>-lfs_stub;-lnet_stub;%(AdditionalDependencies)</AdditionalDependencies>
		]]
	end


--
-- On the PS3, sibling libraries should be linked directly.
--

	function suite.includeSiblings_onPS3SiblingLinks()
		system "PS3"
		links { "MyProject2" }
		test.createproject(sln)
		kind "StaticLib"
		system "PS3"
		prepare()
		test.capture [[
		<Link>
			<SubSystem>Windows</SubSystem>
			<GenerateDebugInformation>false</GenerateDebugInformation>
			<AdditionalDependencies>libMyProject2.a;%(AdditionalDependencies)</AdditionalDependencies>
		]]
	end