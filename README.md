# AIM ZERO · 零点练枪

面向无畏契约玩家的简体中文离线练枪工具。v0.3.0-beta.1 提供大角度定位、小靶微调、人形头线切换、动态跟枪和急停预瞄。一键热身 10 分钟。项目使用 Godot 4.7.2 Compatibility、240 Hz 固定仿真与独立渲染。

Windows 10/11 x64 用户解压便携 ZIP 后运行 AIM-ZERO.exe。见[使用说明](使用说明.txt)、[更新日志](CHANGELOG.md)、[重构报告](REFACTOR.md)与[技术参考及许可](REFERENCES.md)。硬件性能目标待真机验证。

开发时使用 Godot 4.7.2 导入 project.godot。在项目目录运行：

~~~sh
godot --headless --editor --import
godot --headless --script tests/run.gd
godot --headless --script tests/beta.gd
godot --headless -- --smoke-test
mkdir -p build
godot --headless --export-release Windows build/AIM-ZERO.exe
~~~
