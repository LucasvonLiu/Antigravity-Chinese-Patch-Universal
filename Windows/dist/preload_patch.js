// Antigravity Chinese Localization Patch (macOS Optimized)
// https://github.com/good9527/Antigravity-Chinese-Patch — 深度重写版
// 修复：代码区域隔离 / MutationObserver 节流 / 子串误伤消除
(function () {
  'use strict';

  // ============================================================
  //  §1  翻译字典 (Map —— 比普通对象查找更快)
  // ============================================================
  const dictionary = new Map(Object.entries({
    'New Conversation': '新建对话',
    'Conversation History': '历史对话',
    'Scheduled Tasks': '计划任务',
    'Projects': '项目',
    'Conversations': '对话',
    'Settings': '设置',
    'Untitled Conversation': '无标题对话',
    'No conversations yet': '暂无对话',
    'See all': '查看全部',
    'Install IDE': '安装 IDE',
    'Close': '关闭',
    'Cancel': '取消',
    'Save': '保存',
    'Delete': '删除',
    'Rename': '重命名',
    'Ask anything, @ to mention, / for actions': '问我任何问题，用 @ 提及文件，用 / 执行动作',
    'Open': '打开',
    'Edit': '编辑',
    'Customize': '定制',

    // 侧栏导航
    'Account': '账户',
    'Permissions': '权限',
    'Appearance': '外观',
    'Customizations': '自定义',
    'Browser': '浏览器',
    'App': '应用',
    'Not in Project': '非项目对话',
    'Provide Feedback': '提交反馈',
    'General': '常规',
    'Models': '模型',
    'Shortcuts': '快捷键',

    // 顶部菜单
    'File': '文件',
    'View': '视图',
    'Window': '窗口',
    'Help': '帮助',
    'New Window': '新建窗口',
    'Create Project': '创建项目',
    'Command Palette': '命令面板',
    'Check for Updates': '检查更新',

    // 反馈页
    'Feedback Type': '反馈类型',
    'Bug Report': '缺陷报告',
    'Feature Request': '功能需求',
    'Auth and Billing': '账户与账单',
    'General Feedback': '常规反馈',
    'Description': '问题描述',
    'Steps to reproduce the issue': '重现步骤',
    'Expected behavior': '预期结果',
    'Actual behavior': '实际结果',
    'Any error messages': '错误提示信息',
    'Any relevant information': '其他相关信息',
    'Describe the bug you encountered...': '请详细描述您遇到的缺陷(Bug)...',
    'Steps to Reproduce': '重现步骤说明',
    'Attach a screenshot (optional)': '添加截图 (可选)',
    'Attach Antigravity server logs': '附带 Antigravity 服务端日志',
    'Submit': '提交',
    'Please list the steps to reproduce the issue': '请列出重现此问题的步骤',
    'Please describe the issue in detail. The more actionable your feedback, the quicker our team can address your request. Some helpful information includes': '请详细描述您遇到的问题。您的反馈越具体，我们的团队就能越快地处理您的请求。一些有帮助的信息包括',

    // 快捷键页
    'RECOMMENDED': '推荐快捷键',
    'NAVIGATION': '界面导航',
    'CONVERSATION': '对话交互',
    'LAYOUT CONTROLS': '布局控制',
    'Open Conversation Picker': '打开对话选择器',
    'Open File Search': '打开文件搜索',
    'Focus Input': '聚焦输入框',
    'Go Back': '后退',
    'Go Forward': '前进',
    'File Picker': '打开文件选择器',
    'Select Previous Conversation': '选择上一个对话',
    'Select Next Conversation': '选择下一个对话',
    'Open Settings': '打开设置中心',
    'Toggle Model Selector': '切换模型选择器',
    'Toggle Voice Recording': '开启/关闭语音录制',
    'Find in Pane': '在窗格中查找',
    'Toggle Sidebar': '开启/关闭侧边栏',
    'Toggle Auxiliary Pane': '开启/关闭辅助窗格',
    'Zoom In': '放大',
    'Zoom Out': '缩小',
    'Reset Zoom': '重置缩放',

    // 权限与安全
    'Agent Settings': '智能体设置',
    'Security Preset': '安全预设',
    'Turbo Mode': '极速模式',
    'Turbo mode': '极速模式',
    'Agent Behavior': '智能体行为',
    'Artifact Review Policy': 'Artifact 审核策略',
    'Always Proceed': '始终继续',
    'Always Ask': '始终询问',
    'Local Permissions': '本地权限',
    'global settings': '全局设置',
    'File Access Rules': '文件访问规则',
    'Network Access Rules': '网络访问规则',
    'Terminal Commands': '终端命令',
    'Commands Outside Sandbox': '沙箱外命令',
    'MCP Tools': 'MCP 工具',
    'Default': '默认',
    'Full Machine': '完全机器访问',
    'Custom': '自定义',
    'Danger Zone': '危险区域',
    'Delete Project': '删除项目',

    // 安全预设描述
    'Cautious': '谨慎模式',
    'Balanced': '均衡模式',
    'Auto': '自动模式',
    'Automatic': '自动',
    'Allow': '允许',
    'Deny': '拒绝',
    'Ask': '询问',
    'Allowed': '已允许',
    'Denied': '已拒绝',
    'Add Rule': '添加规则',
    'Add Path': '添加路径',
    'Add URL': '添加 URL',
    'Add Command': '添加命令',
    'No rules defined': '暂未定义规则',
    'Workspace': '工作区',
    'Global': '全局',
    'Inherited': '已继承',
    'Override': '覆盖',
    'Reset to Default': '恢复默认值',
    'Unsaved Changes': '有未保存的更改',
    'Save Changes': '保存更改',
    'Discard Changes': '丢弃更改',
    'Apply': '应用',
    'Enabled': '已启用',
    'Disabled': '已禁用',
    'On': '开启',
    'Off': '关闭',
    'None': '无',
    'Loading...': '加载中...',
    'Error': '错误',
    'Warning': '警告',
    'Success': '成功',
    'Info': '提示',
    'Confirm': '确认',
    'Yes': '是',
    'No': '否',
    'OK': '确认',
    'Done': '完成',
    'Back': '返回',
    'Next': '下一步',
    'Previous': '上一步',
    'Finish': '完成',
    'Continue': '继续',
    'Skip': '跳过',
    'Reset': '重置',

    // 项目设置
    'Folders': '项目文件夹',
    '+ Add Folder': '+ 添加文件夹',
    'Project-Specific Settings': '项目特定设置',
    'Go To Projects': '前往项目',
    'File Permissions': '文件权限',
    'Network Permissions': '网络权限',
    'Terminal & Tooling Permissions': '终端与工具权限',

    // 客户端设置
    'App Settings': '应用设置',
    'Prevent Sleep': '防止睡眠',
    'Keep In Menu Bar': '保留在菜单栏中',
    'Notifications': '通知',
    'Notification Settings': '通知设置',
    'Open System Preferences': '打开系统偏好设置',

    // 浏览器设置
    'Browser Settings': '浏览器设置',
    'Browser Javascript Execution Policy': '浏览器 JS 执行策略',
    'Actuation Permissions': '执行权限',
    'Browser Actuation Rules': '浏览器操作规则',

    // 自定义 / MCP
    'Token Usage': 'Token 用量',
    'Installed MCP Servers': '已安装的 MCP 服务',
    'Add MCP +': '+ 添加 MCP 服务',
    'Refresh': '刷新',
    'No MCP Servers': '暂无 MCP 服务',
    'Build With Google Plugins': '基于 Google 官方插件构建',

    // 模型 / 额度
    'Model Credits': 'AI 额度',
    'Enable AI Credit Overages': '允许超额使用 AI 额度',
    'See Activity': '查看活动',
    'Get More AI Credits': '获取更多 AI 额度',
    'Model Quota': '模型配额',

    // 外观
    'Chat Settings': '聊天设置',
    'Verbose agent chat': '显示详细思考过程',
    'Preset': '预设主题色',
    'Default Light': '默认浅色',
    'Default Dark': '默认深色',
    'Background': '背景底色',
    'Foreground': '前景文字字色',
    'Accent': '全局强调色',
    'Light Theme': '浅色主题',
    'Dark Theme': '深色主题',
    'System': '跟随系统',
    'Light': '浅色',
    'Dark': '深色',

    // 账户
    'Marketing Emails': '接收产品推广与技术周报',
    'Upgrade': '订阅升级',
    'Sign Out': '退出当前账户',
    'Terms of Service': '服务条款说明',
    'Email': '邮箱账号',

    // 上下文菜单
    'Add Context': '添加上下文',
    'Media': '媒体文件 (图片/视频)',
    'Mentions': '提及项 (@ 符号)',
    'Actions': '动作指令 (/ 符号)',

    // 窗口控制
    'Minimize': '最小化',
    'Maximize': '最大化',
    'Toggle Developer Tools': '切换开发者工具',

    // 链接片段
    'Inherits from': '继承自',
    'Local permissions have higher priority': '本地权限具有更高优先级',
    'Learn more': '了解更多',
    '. Local permissions have higher priority': '。本地权限具有更高优先级',
    'Learn more about ': '了解更多关于 ',
    'Learn more about': '了解更多关于',

    // 搜索与通用操作
    'Search conversations...': '搜索对话...',
    'Filter': '筛选',
    'Enable Telemetry': '允许收集匿名使用数据',
    'Manually customize individual settings.': '手动配置具体的权限规则。',
    'Search': '搜索',
    'Copy': '复制',
    'Copied!': '已复制！',
    'Clear All': '清除全部',
    'Clear History': '清除历史记录',
    'Stop generating': '停止生成',
    'Regenerate': '重新生成',
    'Retry': '重试',
    'Advanced Settings': '高级设置',
    'Updates': '更新',
    'Review': '审核',
    'Plan': '订阅计划',
    'Your Plan:': '订阅计划：',
    'Google AI Pro': 'Google AI 专业版',
    'Google AI Ultra': 'Google AI 旗舰版',
    'You can upgrade to a Google AI Ultra plan to receive higher rate limits.': '您可以升级到 Google AI 旗舰版计划以获取更高的速率限制。',
    'Verbose Agent Chat': '展示智能体完整思考步骤',
    'Conversation Width': '对话区域宽度',
    'Configure the maximum width of the conversation panel.': '配置对话面板的最大宽度。',
    'Gemini Models': 'Gemini 模型',
    'Claude and GPT models': 'Claude 和 GPT 模型',
    'Weekly Limit': '每周额度限制',
    'Five Hour Limit': '5小时额度限制',
    'Within each group, models share a weekly limit and a 5-hour limit. Quota is consumed proportionally to the cost of the tokens. Thus, limits will last longer with shorter tasks or using more cost-effective models. The 5-hour limit smooths out aggregate demand to fairly distribute global capacity across all users, while your weekly limit is tied directly to your individual tier.': '在每个分组内，模型共享每周和 5 小时的额度限制。配额的消耗与所用 Token 的成本成比例。因此，任务越短或使用越具性价比的模型，限额的持续时间越长。5 小时额度限制用于平抑总体需求，以便在所有用户之间公平分配全球服务能力，而您的每周额度限制则直接与您的个人等级挂钩。',

    // 状态指示 & 思考步骤
    'Working..': '正在处理..',
    'Working...': '正在处理...',
    'Working': '正在处理',
    'Thinking..': '正在思考..',
    'Thinking...': '正在思考...',
    'Thinking': '正在思考',
    'Analyzing..': '正在分析..',
    'Analyzing...': '正在分析...',
    'Analyzing': '正在分析',

    // 思考步骤折叠块标签
    'Thought for': '思考用时',
    'Thought': '思考过程',
    'Thinking step': '思考步骤',
    'thinking step': '思考步骤',
    'thinking steps': '思考步骤',
    'Thinking Steps': '思考步骤',
    'Show thinking': '展开思考过程',
    'Hide thinking': '收起思考过程',
    'Show thought': '展开思考过程',
    'Hide thought': '收起思考过程',
    'Show Thinking': '展开思考过程',
    'Hide Thinking': '收起思考过程',
    'View thinking': '查看思考过程',
    'View Thinking': '查看思考过程',
    'Expanded': '已展开',
    'Collapsed': '已收起',
    'Expand': '展开',
    'Collapse': '收起',
    'Show details': '显示详情',
    'Hide details': '隐藏详情',
    'Show more': '显示更多',
    'Show less': '显示更少',
    'Read more': '阅读更多',
    'Read less': '收起内容',
    'See more': '查看更多',
    'See less': '收起内容',
    'View more': '查看更多',
    'View less': '收起内容',

    // 对话操作
    'Message': '消息',
    'Messages': '消息列表',
    'Reply': '回复',
    'Edit message': '编辑消息',
    'Delete message': '删除消息',
    'Copy message': '复制消息',
    'Regenerate response': '重新生成回复',
    'New message': '新消息',
    'Send message': '发送消息',
    'Type a message': '输入消息...',
    'You': '你',
    'Assistant': '助手',
    'User': '用户',
    'System': '系统',
    'Pending': '等待中',
    'Streaming': '流式输出中',
    'Complete': '已完成',
    'Failed': '失败',
    'Cancelled': '已取消',
    'Interrupted': '已中断',
    'Paused': '已暂停',
    'Resumed': '已恢复',
    'Queued': '等待队列',
    'Processing': '处理中',
    'Generating': '生成中',
    'Loading': '加载中',

    // 工具调用状态
    'Tool call': '工具调用',
    'Tool calls': '工具调用列表',
    'Running tool': '正在执行工具',
    'Tool result': '工具返回结果',
    'Function call': '函数调用',
    'Function result': '函数返回结果',
    'Calling': '调用中',
    'Called': '已调用',
    'Executed': '已执行',
    'Execution': '执行',
    'Result': '结果',
    'Output': '输出',
    'Input': '输入',
    'Error': '错误',
    'Timeout': '超时',
    'Rate limited': '速率受限',
    'Permission denied': '权限被拒绝',

    // 文件操作状态
    'Reading file': '读取文件中',
    'Writing file': '写入文件中',
    'Creating file': '创建文件中',
    'Deleting file': '删除文件中',
    'Editing file': '编辑文件中',
    'Searching file': '搜索文件中',
    'File read': '文件已读取',
    'File written': '文件已写入',
    'File created': '文件已创建',
    'File deleted': '文件已删除',
    'File edited': '文件已编辑',
    'Running command': '运行命令中',
    'Command executed': '命令已执行',
    'Searching web': '搜索网络中',
    'Web search': '网络搜索',
    'Browsing': '浏览中',
    'Navigating': '导航中',

    // 长描述文案（精确匹配，修正原版 "and" 未翻译的 bug）
    'Requires manual review for all terminal commands and file accesses outside of the working folders': '对工作区外的所有终端命令和文件访问均需要手动审核',
    'All terminal commands require review. The agent can read or write to any file in the machine': '所有终端命令都需要审核。智能体可以读取或写入系统中的任何文件',
    'Disables all safety barriers for maximal iteration velocity': '禁用所有安全屏障以换取最大迭代速度',
    'Permanently delete this project and all of its conversations': '永久删除此项目及其所有的对话记录',
    'Agent settings and permissions for conversations outside of projects': '项目外部对话的智能体设置与权限',
    'Choose a predefined security preset for the agent. This controls terminal auto-execution policy, and file access policy': '为智能体选择预设的安全级别。这控制了终端命令自动执行策略和文件访问策略',
    'Learn more about Turbo mode': '了解关于极速模式的详情',
    'Learn more about Turbo Mode': '了解关于极速模式的详情',
    "Specifies Agent's behavior when asking for review on artifacts, which are documents it creates to enable a richer conversation experience": '指定智能体在请求审核其创建的产物（即为了提供更丰富对话体验而生成的文档）时的动作行为',
    'Inherits from global settings. Local permissions have higher priority. Learn more': '继承自全局设置。工作区本地权限具有更高的优先级。了解更多',
    'Configure allowed and denied paths for file reads and writes': '配置允许和拒绝的文件读取及写入路径',
    'Configure allowed and denied URLs for reading': '配置允许和拒绝访问的网络链接 (URL)',
    'Configure allowed terminal commands': '配置允许在系统终端执行的命令白名单',
    'Configure allowed commands outside the sandbox': '配置允许在沙箱环境外部直接执行的系统命令',
    'Manage project folders, agent settings, and permissions': '管理当前工作区的项目文件夹、智能体设定以及访问控制权限',
    'Manage application settings': '管理本客户端应用程序的全局基础设置',
    'Prevent the computer from sleeping while the app is running': '阻止计算机在 Antigravity 应用运行期间自动进入系统睡眠状态',
    'The app will be accessible from the menu bar and will keep running in the background when all windows are closed': '关闭所有窗口后，应用仍可通过顶部菜单栏/系统托盘进行访问，并在系统后台静默运行',
    "To modify notification settings, open your operating system's system preferences": '若需自定义修改应用通知设置，请打开您计算机操作系统的系统首选项进行调整',
    'Configure the browser subagent. It requires Google Chrome to be installed. The browser subagent can be invoked by typing /browser in the conversation input box': '配置浏览器子智能体服务（需要安装 Google Chrome 浏览器）。在聊天窗口中输入 /browser 即可召唤浏览器助手',
    'Controls whether the agent can run custom JavaScript to automate complex browser actions': '控制智能体是否可以通过执行自定义的 JavaScript 脚本来自动化处理复杂的网页浏览操作',
    'Configure allowed and denied URLs for browser actuation': '配置允许和拒绝浏览器助手进行模拟网页交互的网址(URL)规则',
    'Configure default behaviors, skills, and MCP servers. Learn more': '统一配置智能体的默认动作行为、专属技能以及 Model Context Protocol (MCP) 服务器。点击了解更多',
    'The breakdown below shows token usage from customizations like skills, rules, and MCP. If the budget is exceeded, large customizations will be truncated automatically': '下方表格展示了自定义技能、规则库以及 MCP 等扩展功能的 Token 消耗明细。若超出限额，较长的自定义内容会被底层截断',
    'No customizations found for this workspace': '当前工作区尚未发现任何自定义技能、规则或服务器设置',
    "You currently don't have any MCP Servers installed. Add an MCP server above": '您当前尚未部署任何 MCP 服务器。请通过上方的按钮添加一个 MCP 服务',
    'Configure AI models and view your quota': '在此处配置您专属的 AI 语言模型，并实时查询各模型的配额余量',
    "When toggled on, Antigravity will use your AI credits to fulfill model requests once you're out of model quota. Antigravity will always use your model quota first before using AI credits": '开启此开关后，若您的每日免费额度耗尽，Antigravity 将使用您的付费 AI 账户点数继续处理请求。系统会始终优先消耗您的每日免费配额',
    "Configure the agent's visual theme and display preferences": '配置智能体的整体视觉配色主题与窗口显示偏好',
    'Display and preserve intermediate thinking steps': '在聊天界面实时渲染并保留智能体在执行任务时的完整思考过程 (Thinking Steps)',
    'Select light, dark, or inherit system settings': '选择明亮主题、深色主题，或直接同步您操作系统的双色外观',
    'Configure global allowed and denied resource permissions. Learn more': '配置系统全局允许或禁止的硬件及软件资源访问权限。点击了解更多',
    'Modify scoped permissions, folders, and agent settings like Sandbox and Terminal Command Execution': '全局配置特定工作区的独立授权、挂载文件夹，以及命令沙箱执行等高阶环境设定',
    'Configure external tools via Model Context Protocol': '通过业内通用的 Model Context Protocol (MCP) 统一配置和扩展外部调试工具',
    'Manage your plan, credentials, and general preferences': '便捷管理您的账户订阅计划、安全凭证以及全局通用系统偏好',
    'When toggled on, Antigravity collects usage data to help Google enhance performance and features': '开启此选项后，Antigravity 将收集部分匿名使用数据，以帮助 Google 持续优化大模型性能与客户端交互功能',
    'Receive product updates, tips, and promotions from Google Antigravity via email': '允许通过电子邮箱定期接收来自 Google Antigravity 的产品迭代动态、使用技巧以及活动信息',
    'You can upgrade to a Google AI Ultra plan to receive the highest rate limits': '您可以随时升级至 Google AI 旗舰版 (Ultra Plan) 以获取极速响应和无限制的配额限流额度',
    'By using this app, you agree to its Terms of Service': '继续使用本客户端应用程序，即代表您完全知晓并同意其用户服务协议与隐私条款',
    'Keyboard shortcuts for quick navigation and control': '使用精心设计的键盘快捷键来快速导航、切换窗口并控制智能体的高频操作',
    'By using this app, you agree to its': '继续使用本客户端应用程序，即代表您同意其',
    'Your Plan: Google AI Pro': '订阅计划：Google AI 专业版',
    'Your Plan: Google AI Ultra': '订阅计划：Google AI 旗舰版',
    'Configure global allowed and denied resource permissions.': '配置全局允许和拒绝的资源权限。',
    'Configure default behaviors, skills, and MCP servers.': '配置默认行为、技能和 MCP 服务。',
    'Configure the browser subagent. It requires': '配置浏览器子智能体。运行此功能需要安装',
    'to be installed. The browser subagent can be invoked by typing /browser in the conversation input box.': '。您可以在输入框中输入 /browser 来召唤浏览器助手。',
    'to be installed. The browser subagent can be invoked by typing': '。您可以在输入框中输入 ',
    'in the conversation input box.': ' 来召唤浏览器助手。',
    'Are you sure you want to quit?': '您确定要退出吗？',
    'There may be agents or background tasks running.': '可能有智能体或后台任务正在运行。',
    'Quit': '退出',
    'View your available model quota and AI credits. Model quota refreshes periodically based on your plan. Enable AI Credit Overages to continue using models when your quota is exhausted.': '查看您可用的模型配额和 AI 点数。模型配额会根据您的订阅计划定期重置。开启允许超出额度后扣除点数，可在配额耗尽后继续使用模型。',
    'Schedule timer: Timer has expired': '调度定时器：定时器已过期',
  }));

  // ============================================================
  //  §2  预编译正则模式 (动态状态 & 数字模板)
  // ============================================================
  const dynamicPatterns = [
    // See all (12)
    { re: /^See all \((\d+)\)$/, fn: (m) => `查看全部 (${m[1]})` },
    // Refreshes in N hours, M minutes
    {
      re: /^Refreshes in (.+)$/,
      fn: (m) => {
        let t = m[1];
        t = t.replace(/\bhours?\b/g, '小时').replace(/\bminutes?\b/g, '分钟').replace(/,\s*/g, ' ');
        return `额度重置倒计时：${t}`;
      },
    },
    // Your Plan: ...
    {
      re: /^Your Plan: (.+)$/,
      fn: (m) => {
        const plan = m[1].replace('Google AI Pro', 'Google AI 专业版').replace('Google AI Ultra', 'Google AI 旗舰版');
        return `订阅计划：${plan}`;
      },
    },
    // Available AI Credits: $X.XX
    { re: /^Available AI Credits: (.+)$/, fn: (m) => `可用 AI 点数余额: ${m[1]}` },
    // Token budget
    { re: /^(.+) of the customization budget is available\.$/, fn: (m) => `${m[1]} 的自定义 Token 预算当前可用。` },
    // Version X.Y.Z
    { re: /^Version (.+)$/, fn: (m) => `版本 ${m[1]}` },
    // Send feedback as <email>
    { re: /^Send feedback as (.+)$/, fn: (m) => `以 ${m[1]} 的身份发送反馈` },
    // Explored N files / tasks
    { re: /^Explored (\d+) (files?|tasks?)$/i, fn: (m) => `已探索 ${m[1]} 个${m[2].startsWith('f') ? '文件' : '任务'}` },
    // Edited N files
    { re: /^Edited (\d+) files?$/i, fn: (m) => `已编辑 ${m[1]} 个文件` },
    // Timed N seconds
    { re: /^Timed (\d+) seconds?$/i, fn: (m) => `已计时 ${m[1]} 秒` },
    // Thinking for Ns
    {
      re: /^Thinking for (\d+(?:\.\d+)?)\s*(s|seconds?|ms)?$/i,
      fn: (m) => `思考中 (${m[1]}${m[2] && m[2].toLowerCase().startsWith('ms') ? '毫秒' : '秒'})`,
    },
    // Working for Ns
    {
      re: /^Working for (\d+(?:\.\d+)?)\s*(s|seconds?|ms)?$/i,
      fn: (m) => `处理中 (${m[1]}${m[2] && m[2].toLowerCase().startsWith('ms') ? '毫秒' : '秒'})`,
    },
    // Completed/Finished/Done in Ns
    {
      re: /^(?:Completed|Finished|Done) in (\d+(?:\.\d+)?)\s*(s|seconds?|ms)?$/i,
      fn: (m) => `已完成 (耗时 ${m[1]}${m[2] && m[2].toLowerCase().startsWith('ms') ? '毫秒' : '秒'})`,
    },
    // Generated image in Ns
    {
      re: /^Generated image in (\d+(?:\.\d+)?)\s*(s|seconds?|ms)?$/i,
      fn: (m) => `已生成图片 (耗时 ${m[1]}${m[2] && m[2].toLowerCase().startsWith('ms') ? '毫秒' : '秒'})`,
    },
    // You have used some of your weekly limit, it will fully refresh in ...
    {
      re: /^You have used some of your weekly limit, it will fully refresh in (.+)\.$/i,
      fn: (m) => {
        let t = m[1].replace(/\bdays?\b/g, '天').replace(/\bhours?\b/g, '小时').replace(/\bminutes?\b/g, '分钟').replace(/,\s*/g, ' ');
        return `您已消耗了部分每周限额，将在 ${t} 后完全重置。`;
      },
    },
    // You have used some of your 5-hour limit, it will fully refresh in ...
    {
      re: /^You have used some of your 5-hour limit, it will fully refresh in (.+)\.$/i,
      fn: (m) => {
        let t = m[1].replace(/\bhours?\b/g, '小时').replace(/\bminutes?\b/g, '分钟').replace(/,\s*/g, ' ');
        return `您已消耗了部分 5 小时限额，将在 ${t} 后完全重置。`;
      },
    },
    // Bulletproof match for browser subagent description
    {
      re: /^\s*to be installed\. The browser subagent can be invoked by typing\s*\/browser\s*in the conversation input box\s*\.?\s*$/i,
      fn: () => '。您可以在输入框中输入 /browser 来召唤浏览器助手。'
    },
    // Confirm Quit Modal
    {
      re: /^\s*Are you sure you want to quit\s*\??\s*$/i,
      fn: () => '您确定要退出吗？'
    },
    {
      re: /^\s*There may be agents or background tasks running\s*\.?\s*$/i,
      fn: () => '可能有智能体或后台任务正在运行。'
    },
    {
      re: /^\s*Quit\s*$/i,
      fn: () => '退出'
    },
    {
      re: /^\s*Cancel\s*$/i,
      fn: () => '取消'
    },
    // Thinking for N seconds
    {
      re: /^Thought for (\d+(?:\.\d+)?)\s*(s|sec(?:onds?)?)?$/i,
      fn: (m) => `思考用时 ${m[1]} 秒`,
    },
    {
      re: /^Thought for (\d+(?:\.\d+)?)\s*ms$/i,
      fn: (m) => `思考用时 ${m[1]} 毫秒`,
    },
    // Show/Hide thinking (N s)
    {
      re: /^(Show|Hide|View)\s+[Tt]hinking(?:\s*\(([^)]+)\))?$/,
      fn: (m) => {
        const action = m[1].toLowerCase() === 'hide' ? '收起' : '展开';
        const time = m[2] ? ` (${m[2]})` : '';
        return `${action}思考过程${time}`;
      },
    },
    // Thinking (N s)
    {
      re: /^[Tt]hinking\s*\((\d+(?:\.\d+)?)\s*(s|sec(?:onds?)?|ms)?\)$/,
      fn: (m) => {
        const unit = m[2] && m[2].toLowerCase().startsWith('ms') ? '毫秒' : '秒';
        return `思考中 (${m[1]} ${unit})`;
      },
    },
    // Step N of M
    {
      re: /^Step (\d+) of (\d+)$/i,
      fn: (m) => `步骤 ${m[1]} / ${m[2]}`,
    },
    // Ran N tool calls
    {
      re: /^Ran (\d+) tool calls?$/i,
      fn: (m) => `已执行 ${m[1]} 次工具调用`,
    },
    // Used N tokens
    {
      re: /^Used (\d+(?:,\d+)?) tokens?$/i,
      fn: (m) => `已消耗 ${m[1]} 个 Token`,
    },
    // N tokens used
    {
      re: /^(\d+(?:,\d+)?) tokens? used$/i,
      fn: (m) => `已消耗 ${m[1]} 个 Token`,
    },
  ];

  // ============================================================
  //  §3  标点映射
  // ============================================================
  const punctuationMap = { '.': '。', ':': '：', '?': '？', '!': '！', ',': '，' };

  // ============================================================
  //  §4  核心翻译函数
  // ============================================================
  function translateText(text) {
    if (!text) return null;

    // 标准化不换行空格 (React 组件中 \u00a0 常见)
    const normalized = text.replaceAll('\u00a0', ' ');
    const trimmed = normalized.trim();
    if (!trimmed) return null;

    // 跳过已经是纯中文 / 含中文字符的文本（避免二次翻译）
    if (/^[\u4e00-\u9fff\u3000-\u303f\uff00-\uffef\s\d()（）/\-:：.。,，!！?？]+$/.test(trimmed)) return null;

    // 1. 字典精确匹配
    const exact = dictionary.get(trimmed);
    if (exact) return normalized.replace(trimmed, exact);

    // 2. 去尾标点后匹配
    const lastChar = trimmed[trimmed.length - 1];
    if (punctuationMap[lastChar]) {
      const core = trimmed.slice(0, -1).trim();
      const coreMatch = dictionary.get(core);
      if (coreMatch) return normalized.replace(trimmed, coreMatch + punctuationMap[lastChar]);
    }

    // 3. 动态正则模式匹配
    for (const { re, fn } of dynamicPatterns) {
      const m = trimmed.match(re);
      if (m) return normalized.replace(trimmed, fn(m));
    }

    return null;
  }

  // ============================================================
  //  §5  代码区域隔离 — 绝不翻译代码
  // ============================================================
  const CODE_TAGS = new Set(['PRE', 'CODE', 'TEXTAREA', 'SCRIPT', 'STYLE', 'NOSCRIPT']);
  const CODE_CLASS_FRAGMENTS = [
    'monaco-editor', 'view-lines', 'view-line',
    'CodeMirror', 'cm-editor', 'cm-content',
    'hljs', 'prism-code', 'shiki',
    'code-block', 'codeblock', 'code-container',
    'markdown-code', 'language-',
  ];

  /**
   * 判断一个节点是否位于代码展示区域内。
   * 向上查找祖先元素，如果遇到 <pre>/<code>/<textarea> 或
   * 含有编辑器/代码高亮类名的容器，则认为该节点位于代码区域。
   */
  function isInsideCodeRegion(node) {
    let current = node.nodeType === 1 ? node : node.parentElement;
    // 最多向上查找 20 层，避免极端深层 DOM 的性能问题
    let depth = 0;
    while (current && depth < 20) {
      if (CODE_TAGS.has(current.tagName)) return true;
      if (current.className && typeof current.className === 'string') {
        const cls = current.className;
        for (const frag of CODE_CLASS_FRAGMENTS) {
          if (cls.includes(frag)) return true;
        }
      }
      // 检查 contenteditable（Monaco Editor 使用）
      if (current.getAttribute && current.getAttribute('role') === 'code') return true;
      current = current.parentElement;
      depth++;
    }
    return false;
  }

  // ============================================================
  //  §6  DOM 遍历翻译
  // ============================================================
  function walk(node) {
    if (!node) return;

    if (node.nodeType === 3) {
      // TEXT_NODE
      if (isInsideCodeRegion(node)) return;
      const translated = translateText(node.nodeValue);
      if (translated !== null) node.nodeValue = translated;
    } else if (node.nodeType === 1) {
      // ELEMENT_NODE — 对于已知的代码容器，直接跳过整棵子树
      if (CODE_TAGS.has(node.tagName)) return;
      if (node.className && typeof node.className === 'string') {
        for (const frag of CODE_CLASS_FRAGMENTS) {
          if (node.className.includes(frag)) return;
        }
      }

      // placeholder 翻译
      if (node.placeholder) {
        const translated = translateText(node.placeholder);
        if (translated !== null) node.placeholder = translated;
      }
      // input[type=button|submit] value 翻译
      if (node.tagName === 'INPUT' && (node.type === 'button' || node.type === 'submit')) {
        const translated = translateText(node.value);
        if (translated !== null) node.value = translated;
      }
      // title 属性翻译
      if (node.title) {
        const translated = translateText(node.title);
        if (translated !== null) node.title = translated;
      }
      // aria-label 翻译
      if (node.getAttribute && node.getAttribute('aria-label')) {
        const ariaLabel = node.getAttribute('aria-label');
        const translated = translateText(ariaLabel);
        if (translated !== null) node.setAttribute('aria-label', translated);
      }

      // Shadow DOM 穿透
      if (node.shadowRoot) walk(node.shadowRoot);
      for (let child = node.firstChild; child; child = child.nextSibling) {
        walk(child);
      }
    } else if (node.nodeType === 11) {
      // DOCUMENT_FRAGMENT_NODE (ShadowRoot)
      for (let child = node.firstChild; child; child = child.nextSibling) {
        walk(child);
      }
    }
  }

  // ============================================================
  //  §7  MutationObserver — requestAnimationFrame 节流
  // ============================================================
  let pendingMutations = [];
  let rafScheduled = false;

  function processPendingMutations() {
    const mutations = pendingMutations;
    pendingMutations = [];
    rafScheduled = false;

    // 暂时断开 observer，避免翻译操作触发二次监听
    observer.disconnect();

    for (const mutation of mutations) {
      if (mutation.type === 'childList') {
        for (const addedNode of mutation.addedNodes) {
          walk(addedNode);
        }
      } else if (mutation.type === 'characterData') {
        if (!isInsideCodeRegion(mutation.target)) {
          const translated = translateText(mutation.target.nodeValue);
          if (translated !== null) mutation.target.nodeValue = translated;
        }
      } else if (mutation.type === 'attributes') {
        const target = mutation.target;
        if (isInsideCodeRegion(target)) continue;
        if (mutation.attributeName === 'placeholder' && target.placeholder) {
          const translated = translateText(target.placeholder);
          if (translated !== null) target.placeholder = translated;
        }
        if (mutation.attributeName === 'value' && target.tagName === 'INPUT') {
          const translated = translateText(target.value);
          if (translated !== null) target.value = translated;
        }
      }
    }

    startObserver();
  }

  const observer = new MutationObserver((mutations) => {
    pendingMutations.push(...mutations);
    if (!rafScheduled) {
      rafScheduled = true;
      requestAnimationFrame(processPendingMutations);
    }
  });

  function startObserver() {
    observer.observe(document.documentElement, {
      childList: true,
      subtree: true,
      characterData: true,
      attributes: true,
      attributeFilter: ['placeholder', 'value'],
    });
  }

  // ============================================================
  //  §8  document.title 拦截
  // ============================================================
  try {
    const originalTitleDescriptor = Object.getOwnPropertyDescriptor(Document.prototype, 'title');
    if (originalTitleDescriptor && originalTitleDescriptor.set) {
      Object.defineProperty(document, 'title', {
        get() {
          return originalTitleDescriptor.get.call(this);
        },
        set(val) {
          if (!val) {
            originalTitleDescriptor.set.call(this, val);
            return;
          }
          const trimmed = val.trim();
          let translated = val;
          const exact = dictionary.get(trimmed);
          if (exact) {
            translated = val.replace(trimmed, exact);
          } else if (trimmed.includes(' - Antigravity')) {
            const part = trimmed.replace(' - Antigravity', '').trim();
            const partMatch = dictionary.get(part);
            if (partMatch) translated = `${partMatch} - Antigravity`;
          }
          originalTitleDescriptor.set.call(this, translated);
        },
      });
    }
  } catch (e) {
    console.error('[CN Patch] Failed to hook document.title:', e);
  }

  // ============================================================
  //  §8.5  定时全量扫描 — 应对懒加载 / Shadow DOM 漏译
  //  每 500 ms 扫描一次 body，并额外翻译 data-* 属性
  // ============================================================
  function translateDataAttributes(root) {
    try {
      // 翻译带有语义文本的 data-* 属性（如 data-tooltip、data-label 等）
      const selectors = [
        '[data-tooltip]', '[data-label]', '[data-title]',
        '[data-placeholder]', '[data-content]', '[data-text]',
        '[aria-description]', '[aria-placeholder]',
      ];
      const elements = (root || document).querySelectorAll(selectors.join(','));
      elements.forEach(el => {
        ['data-tooltip','data-label','data-title','data-placeholder','data-content','data-text'].forEach(attr => {
          const val = el.getAttribute(attr);
          if (val) {
            const t = translateText(val);
            if (t !== null) el.setAttribute(attr, t);
          }
        });
        const ariaDesc = el.getAttribute('aria-description');
        if (ariaDesc) {
          const t = translateText(ariaDesc);
          if (t !== null) el.setAttribute('aria-description', t);
        }
        const ariaPlaceholder = el.getAttribute('aria-placeholder');
        if (ariaPlaceholder) {
          const t = translateText(ariaPlaceholder);
          if (t !== null) el.setAttribute('aria-placeholder', t);
        }
      });
    } catch (e) { /* ignore */ }
  }

  let scanCount = 0;
  const MAX_FAST_SCANS = 60; // 前30秒每500ms一次，之后降速
  function schedulePeriodicScan() {
    const interval = scanCount < MAX_FAST_SCANS ? 500 : 3000;
    setTimeout(() => {
      try {
        observer.disconnect();
        if (document.body) {
          walk(document.body);
          translateDataAttributes(document);
        }
        // 穿透所有 Shadow DOM
        document.querySelectorAll('*').forEach(el => {
          if (el.shadowRoot) {
            walk(el.shadowRoot);
            translateDataAttributes(el.shadowRoot);
          }
        });
        startObserver();
      } catch (e) { /* ignore */ }
      scanCount++;
      schedulePeriodicScan();
    }, interval);
  }

  schedulePeriodicScan();

  // ============================================================
  //  §9  云端字典热更新（localStorage 缓存 + GitHub 异步拉取）
  // ============================================================
  try {
    const cached = localStorage.getItem('antigravity_chinese_patch_dict');
    if (cached) {
      const data = JSON.parse(cached);
      for (const [k, v] of Object.entries(data)) {
        dictionary.set(k, v);
      }
    }
  } catch (e) {
    console.error('[CN Patch] Failed to load cached cloud dictionary:', e);
  }

  fetch('https://raw.githubusercontent.com/good9527/Antigravity-Chinese-Patch/main/dist/dictionary.json')
    .then((res) => {
      if (res.ok) return res.json();
      throw new Error('Network response was not ok');
    })
    .then((data) => {
      if (data && typeof data === 'object') {
        localStorage.setItem('antigravity_chinese_patch_dict', JSON.stringify(data));
        for (const [k, v] of Object.entries(data)) {
          dictionary.set(k, v);
        }
        console.log('[CN Patch] Cloud dictionary updated. Total keys:', dictionary.size);
        // 立即刷新翻译
        if (document.body) walk(document.body);
      }
    })
    .catch((err) => {
      console.warn('[CN Patch] Cloud update unavailable, using local dictionary.', err);
    });

  // ============================================================
  //  §10  启动入口
  // ============================================================
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
      walk(document.body);
      startObserver();
    });
  } else {
    walk(document.body);
    startObserver();
  }

  console.log('[CN Patch] Antigravity 中文汉化补丁已加载 (macOS 优化版)');
})();
