<?xml version='1.0' encoding='UTF-8'?>
<Project Type="Project" LVVersion="20008000">
	<Property Name="NI.LV.All.SaveVersion" Type="Str">20.0</Property>
	<Property Name="NI.LV.All.SourceOnly" Type="Bool">true</Property>
	<Property Name="NI.Project.Description" Type="Str"></Property>
	<Item Name="My Computer" Type="My Computer">
		<Property Name="server.app.propertiesEnabled" Type="Bool">true</Property>
		<Property Name="server.control.propertiesEnabled" Type="Bool">true</Property>
		<Property Name="server.tcp.enabled" Type="Bool">false</Property>
		<Property Name="server.tcp.port" Type="Int">0</Property>
		<Property Name="server.tcp.serviceName" Type="Str">My Computer/VI Server</Property>
		<Property Name="server.tcp.serviceName.default" Type="Str">My Computer/VI Server</Property>
		<Property Name="server.vi.callsEnabled" Type="Bool">true</Property>
		<Property Name="server.vi.propertiesEnabled" Type="Bool">true</Property>
		<Property Name="specify.custom.address" Type="Bool">false</Property>
		<Item Name="Modules" Type="Folder">
			<Item Name="G-AI Core.lvlib" Type="Library" URL="../G-AI Core/G-AI Core.lvlib"/>
		</Item>
		<Item Name="tests" Type="Folder">
			<Property Name="NI.SortType" Type="Int">3</Property>
			<Item Name="G-AI tests.lvlib" Type="Library" URL="../../tests/G-AI tests.lvlib"/>
			<Item Name="Run G-AI Tests CICD.vi" Type="VI" URL="../../tests/Run G-AI Tests CICD.vi"/>
		</Item>
		<Item Name="Tools" Type="Folder">
			<Item Name="add object to vi.vi" Type="VI" URL="../tools/add object to vi.vi"/>
			<Item Name="add subvi to vi.vi" Type="VI" URL="../tools/add subvi to vi.vi"/>
			<Item Name="cleanup vi.vi" Type="VI" URL="../tools/cleanup vi.vi"/>
			<Item Name="close vi.vi" Type="VI" URL="../tools/close vi.vi"/>
			<Item Name="connect objects.vi" Type="VI" URL="../tools/connect objects.vi"/>
			<Item Name="create control.vi" Type="VI" URL="../tools/create control.vi"/>
			<Item Name="create new vi.vi" Type="VI" URL="../tools/create new vi.vi"/>
			<Item Name="get available objects.vi" Type="VI" URL="../tools/get available objects.vi"/>
			<Item Name="get available properties.vi" Type="VI" URL="../tools/get available properties.vi"/>
			<Item Name="get control.vi" Type="VI" URL="../tools/get control.vi"/>
			<Item Name="get enum.vi" Type="VI" URL="../tools/get enum.vi"/>
			<Item Name="get object terminals.vi" Type="VI" URL="../tools/get object terminals.vi"/>
			<Item Name="get project.vi" Type="VI" URL="../tools/get project.vi"/>
			<Item Name="get structure diagram.vi" Type="VI" URL="../tools/get structure diagram.vi"/>
			<Item Name="get vi details.vi" Type="VI" URL="../tools/get vi details.vi"/>
			<Item Name="rename object.vi" Type="VI" URL="../tools/rename object.vi"/>
			<Item Name="set property.vi" Type="VI" URL="../tools/set property.vi"/>
		</Item>
		<Item Name="Dependencies" Type="Dependencies"/>
		<Item Name="Build Specifications" Type="Build">
			<Item Name="G-AI Source Distribution" Type="Source Distribution">
				<Property Name="Bld_autoIncrement" Type="Bool">true</Property>
				<Property Name="Bld_buildCacheID" Type="Str">{898F38AA-DE03-4A40-87C8-904539F1F132}</Property>
				<Property Name="Bld_buildSpecName" Type="Str">G-AI Source Distribution</Property>
				<Property Name="Bld_excludedDirectory[0]" Type="Path">vi.lib</Property>
				<Property Name="Bld_excludedDirectory[0].pathType" Type="Str">relativeToAppDir</Property>
				<Property Name="Bld_excludedDirectory[1]" Type="Path">instr.lib</Property>
				<Property Name="Bld_excludedDirectory[1].pathType" Type="Str">relativeToAppDir</Property>
				<Property Name="Bld_excludedDirectory[2]" Type="Path">user.lib</Property>
				<Property Name="Bld_excludedDirectory[2].pathType" Type="Str">relativeToAppDir</Property>
				<Property Name="Bld_excludedDirectory[3]" Type="Path">resource/objmgr</Property>
				<Property Name="Bld_excludedDirectory[3].pathType" Type="Str">relativeToAppDir</Property>
				<Property Name="Bld_excludedDirectory[4]" Type="Path">/C/ProgramData/National Instruments/InstCache/26.0</Property>
				<Property Name="Bld_excludedDirectory[5]" Type="Path">/C/Users/jgoebel/OneDrive - Emerson/Dokumente/LabVIEW Data/2026(64-bit)/ExtraVILib</Property>
				<Property Name="Bld_excludedDirectoryCount" Type="Int">6</Property>
				<Property Name="Bld_localDestDir" Type="Path">../builds/NI_AB_PROJECTNAME/G-AI Source Distribution</Property>
				<Property Name="Bld_localDestDirType" Type="Str">relativeToCommon</Property>
				<Property Name="Bld_previewCacheID" Type="Str">{9A6AA5AD-321F-48CC-A2C3-62837037F383}</Property>
				<Property Name="Bld_removeVIObj" Type="Int">2</Property>
				<Property Name="Bld_version.build" Type="Int">14</Property>
				<Property Name="Bld_version.major" Type="Int">1</Property>
				<Property Name="Destination[0].destName" Type="Str">Destination Directory</Property>
				<Property Name="Destination[0].path" Type="Path">../builds/NI_AB_PROJECTNAME/G-AI Source Distribution</Property>
				<Property Name="Destination[1].destName" Type="Str">Support Directory</Property>
				<Property Name="Destination[1].path" Type="Path">../builds/NI_AB_PROJECTNAME/G-AI Source Distribution/data</Property>
				<Property Name="Destination[2].destName" Type="Str">MCP tools</Property>
				<Property Name="Destination[2].path" Type="Path">../builds/NI_AB_PROJECTNAME/G-AI Source Distribution/tools</Property>
				<Property Name="DestinationCount" Type="Int">3</Property>
				<Property Name="Source[0].itemID" Type="Str">{05D6038A-C2EC-4DBB-A92C-5914BA47848F}</Property>
				<Property Name="Source[0].type" Type="Str">Container</Property>
				<Property Name="Source[1].Container.applyDestination" Type="Bool">true</Property>
				<Property Name="Source[1].Container.applyInclusion" Type="Bool">true</Property>
				<Property Name="Source[1].Container.depDestIndex" Type="Int">0</Property>
				<Property Name="Source[1].destinationIndex" Type="Int">2</Property>
				<Property Name="Source[1].itemID" Type="Ref">/My Computer/Tools</Property>
				<Property Name="Source[1].sourceInclusion" Type="Str">Include</Property>
				<Property Name="Source[1].type" Type="Str">Container</Property>
				<Property Name="Source[2].destinationIndex" Type="Int">0</Property>
				<Property Name="Source[2].itemID" Type="Ref">/My Computer/Modules/G-AI Core.lvlib</Property>
				<Property Name="Source[2].Library.allowMissingMembers" Type="Bool">true</Property>
				<Property Name="Source[2].sourceInclusion" Type="Str">Include</Property>
				<Property Name="Source[2].type" Type="Str">Library</Property>
				<Property Name="SourceCount" Type="Int">3</Property>
			</Item>
		</Item>
	</Item>
</Project>
