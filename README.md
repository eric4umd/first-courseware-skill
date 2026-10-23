# Eric带你学AI · 教学 Skills

「Eric带你学AI」教学实操视频的配套仓库。这里分享我用来制作英语讲义和课堂网页的两个 Skill，你可以让支持本地 Skill 的 AI 编程助手读取说明，再根据自己的课程制作材料。

我平时先整理一节课的内容，做出讲义，再把讲义转成上课时使用的网页。这个仓库提供这套流程用到的说明、模板和工具。

| Skill | 适合做什么 | 生成什么 |
|---|---|---|
| [Eric Teaching Press](eric-teaching-press/SKILL.md) | 双语讲义、课堂练习、教师讲解 | 可编辑的 Typst 源文件和 A4 PDF |
| [Eric Teaching Stage](eric-teaching-stage/SKILL.md) | 老师控制进度的课堂演示，按需加入听力 | 本地 HTML 网页及配套资源，可在浏览器打开 |

## 示例效果

以下画面由仓库里的虚构示例生成。

讲义示例：

![A4 语法讲义示例](assets/handout-preview.png)

课堂网页示例，老师点击后显示参考答案：

![课堂网页答案展开示例](assets/classroom-preview.png)

## 让 AI 帮你安装

把下面这段话发给 WorkBuddy，或其他能读取文件、执行命令并安装本地 Skill 的 AI 工具。各工具的 Skill 目录不同，让它先确认自己的安装方式。

```text
请帮我安装「Eric带你学AI」的教学 Skills：
https://github.com/eric4umd/teaching-skills

先读仓库 README 和两个 SKILL.md，确认当前工具是否支持本地 Skill。
支持的话，把 eric-teaching-press 和 eric-teaching-stage 分别装到正确的 Skill 目录。
检查需要的 Python、Typst、Node.js 和浏览器；告诉我缺什么、要用来做什么。
安装软件、下载模型或调用付费服务前，先征求我的同意。
先用自带示例做一份讲义和一个课堂网页，检查文件能否打开。
遇到本机没有的路径、字体或工具，说明具体缺项；可跳过的可选功能先跳过。
保留我的原有文件，不覆盖已有 Skill 或课程成品。
最后告诉我文件保存在哪里，以及接下来怎么改成自己的课程。
```

只提供聊天功能、无法读取本地文件或执行命令的 AI 工具，无法直接运行这些脚本。

## 从一节课开始

安装后，可以继续发给 AI：

```text
请用 eric-teaching-press，为初二学生制作一节课的英语讲义，主题是现在完成时。
先确认学生基础、课堂时长和本节目标，再编写内容；学生练习不附答案，教师版在相应题目旁讲解。
我确认讲义后，再用 eric-teaching-stage 把这份讲义做成课堂网页。
网页由老师按空格推进，答案点击后显示。这节课暂时不加听力。
```

把年级、主题和课堂要求换成你的实际情况。先检查题目、答案与讲解，再拿到课堂上使用。

## 软件与可选功能

| 用途 | 需要什么 | 说明 |
|---|---|---|
| 生成讲义 | Python 3、Typst | Press 提供 D1 Marginalia、D2 Grid、D3 Index Cards 三种版式；D2/D3 必须明确选择字体模式 |
| 生成课堂网页 | Python 3 | 默认 D3 外观；另有 Marginalia、Grid、Studio、Exam 主题 |
| 打开课堂网页 | 现代浏览器 | 生成后保留 HTML 和配套文件夹，可离线打开；听力需要事先生成本地音频 |
| 自动检查网页 | Node.js、Playwright 及其浏览器运行时 | 检查翻页、答案显示和布局；软件与浏览器运行时需另外安装 |
| 生成听力 | `stage_setup.sh` 使用的 uv、FFmpeg 和 Python 环境 | 安装脚本会下载依赖和模型；先阅读脚本，按需运行 |

听力默认使用 edge-tts，生成时需要联网，服务使用非官方接口；使用前应自行确认服务条款。Kokoro 在模型准备好后可离线生成。ElevenLabs 是可选的付费方案，需要自己配置 `ELEVENLABS_API_KEY`，使用前确认费用。

Stage 的 Marginalia 主题会按课件文字生成中文字体子集，需要 Python 的 fontTools 和 brotli。所用字体源文件随 Skill 提供；在新机器上使用这个主题前，先检查这两个 Python 包是否已安装。

## 文件在哪里

- `eric-teaching-press/`：讲义 Skill、Typst 模板、字体与编译工具。
- `eric-teaching-stage/`：网页 Skill、课堂组件、主题、虚构示例课与检查脚本。

每个 Skill 的 `SKILL.md` 是 AI 的使用入口，`references/` 是详细说明。示例内容供试用工具和了解格式，不包含学生档案。

## 来源与许可

字体的许可文件保存在对应的字体目录。Stage 随附 GSAP 3.12.7，并保留原始版权声明和许可链接；字体和 GSAP 分别遵循自己的条款。详见 [第三方资源说明](THIRD_PARTY_NOTICES.md)。

本仓库尚未为 Eric 原创的说明、代码和版式指定统一开源许可证；公开可见不代表自动授予这些内容的再分发或商业授权。

如果你从「Eric带你学AI」的视频来到这里，欢迎在对应视频的评论区说说使用情况，或提交 GitHub Issue。描述问题时请删掉学生姓名、联系方式和其他私人信息。
