use AppleScript version "2.4"
use scripting additions

-- ============================================================
--  Antigravity 中文汉化补丁 — macOS 原生图形界面
--  双击即可运行，无需打开终端
-- ============================================================

on run
	-- 定位项目目录（.app 所在的目录）
	set appPath to POSIX path of (path to me)
	set projectDir to do shell script "dirname " & quoted form of appPath
	set helperScript to projectDir & "/lib/patch_helper.sh"
	set patchJS to projectDir & "/dist/preload_patch.js"
	
	-- 检查核心文件是否存在
	try
		do shell script "test -f " & quoted form of helperScript
		do shell script "test -f " & quoted form of patchJS
	on error
		display dialog "❌ 未找到必需的补丁文件。" & return & return & "请确保以下文件存在：" & return & "• lib/patch_helper.sh" & return & "• dist/preload_patch.js" & return & return & "请将本应用放回汉化补丁项目文件夹内。" buttons {"好"} default button "好" with title "文件缺失" with icon stop
		return
	end try
	
	-- 主菜单
	set choice to button returned of (display dialog "Antigravity 中文汉化补丁" & return & "macOS 深度优化版" & return & return & "请选择要执行的操作：" buttons {"检查状态", "卸载还原", "安装汉化"} default button "安装汉化" with title "Antigravity 汉化工具" with icon note)
	
	if choice is "安装汉化" then
		doInstall(helperScript, patchJS)
	else if choice is "卸载还原" then
		doRestore(helperScript)
	else if choice is "检查状态" then
		doCheckStatus(helperScript)
	end if
end run


-- ── 安装/更新汉化 ───────────────────────────────────────
on doInstall(helperScript, patchJS)
	-- 确认安装
	set confirmChoice to button returned of (display dialog "即将安装中文汉化补丁" & return & return & "此操作将会：" & return & "  • 自动关闭 Antigravity 客户端" & return & "  • 注入汉化代码" & return & "  • 重新打包并启动客户端" & return & return & "⏳ 首次运行可能需要下载依赖，请耐心等待约 30 秒。" buttons {"取消", "开始安装"} default button "开始安装" cancel button "取消" with title "安装确认" with icon note)
	
	-- 执行安装
	try
		set cmdResult to do shell script "bash " & quoted form of helperScript & " install " & quoted form of patchJS & " 2>&1"
		
		-- 检查结果
		if cmdResult contains "SUCCESS:" then
			display dialog "✅ 汉化补丁安装成功！" & return & return & "Antigravity 客户端已重新启动。" & return & "请查看汉化效果。" buttons {"太好了"} default button "太好了" with title "安装完成" with icon note
		else if cmdResult contains "ERROR:" then
			set errMsg to extractMessage(cmdResult, "ERROR:")
			display dialog "❌ 安装失败" & return & return & errMsg buttons {"好"} default button "好" with title "安装失败" with icon stop
		else
			display dialog "✅ 操作已完成。" & return & return & cmdResult buttons {"好"} default button "好" with title "完成" with icon note
		end if
	on error errMsg number errNum
		if errNum is -128 then
			-- 用户点了取消
			return
		end if
		display dialog "❌ 安装过程出错" & return & return & errMsg buttons {"好"} default button "好" with title "错误" with icon stop
	end try
end doInstall


-- ── 卸载还原 ────────────────────────────────────────────
on doRestore(helperScript)
	-- 确认还原
	set confirmChoice to button returned of (display dialog "即将卸载汉化补丁并还原官方原版。" & return & return & "此操作将会：" & return & "  • 自动关闭 Antigravity 客户端" & return & "  • 还原原始 preload.js" & return & "  • 重新打包并启动客户端" buttons {"取消", "确认还原"} default button "确认还原" cancel button "取消" with title "卸载确认" with icon caution)
	
	try
		set cmdResult to do shell script "bash " & quoted form of helperScript & " restore 2>&1"
		
		if cmdResult contains "SUCCESS:" then
			display dialog "✅ 已成功还原为官方原版客户端。" buttons {"好"} default button "好" with title "还原完成" with icon note
		else if cmdResult contains "ERROR:" then
			set errMsg to extractMessage(cmdResult, "ERROR:")
			display dialog "❌ 还原失败" & return & return & errMsg buttons {"好"} default button "好" with title "还原失败" with icon stop
		else
			display dialog "✅ 操作已完成。" buttons {"好"} default button "好" with title "完成" with icon note
		end if
	on error errMsg number errNum
		if errNum is -128 then
			return
		end if
		display dialog "❌ 还原过程出错" & return & return & errMsg buttons {"好"} default button "好" with title "错误" with icon stop
	end try
end doRestore


-- ── 检查状态 ─────────────────────────────────────────────
on doCheckStatus(helperScript)
	try
		set cmdResult to do shell script "bash " & quoted form of helperScript & " status 2>&1"
		
		if cmdResult contains "STATUS:" then
			set statusText to extractMessage(cmdResult, "STATUS:")
			display dialog statusText buttons {"好"} default button "好" with title "Antigravity 状态检查" with icon note
		else if cmdResult contains "ERROR:" then
			set errMsg to extractMessage(cmdResult, "ERROR:")
			display dialog "❌ " & errMsg buttons {"好"} default button "好" with title "检查失败" with icon stop
		else
			display dialog cmdResult buttons {"好"} default button "好" with title "状态检查" with icon note
		end if
	on error errMsg
		display dialog "❌ 状态检查出错" & return & return & errMsg buttons {"好"} default button "好" with title "错误" with icon stop
	end try
end doCheckStatus


-- ── 工具函数：提取标记后的消息内容 ─────────────────────
on extractMessage(fullText, marker)
	set resultText to ""
	set paragraphList to paragraphs of fullText
	repeat with p in paragraphList
		set pText to p as text
		if pText starts with marker then
			set msgPart to text ((length of marker) + 1) thru -1 of pText
			if resultText is "" then
				set resultText to msgPart
			else
				set resultText to resultText & return & msgPart
			end if
		end if
	end repeat
	if resultText is "" then
		return fullText
	end if
	return resultText
end extractMessage
