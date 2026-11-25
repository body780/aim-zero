# Viscose S2 五项训练校准记录

按公开排行榜参与人数与训练类型选取具体版本。所有项目为 60 秒，使用项目自有场景、音效和代码。表中角直径为起始参考距离上的估算值。

|原版名称|上榜人数（查询快照）|距离／半径（米）|角直径|资料|
|---|---:|---|---:|---|
|1w6ts reload v2|75957|8 / 0.089|1.27°|[工坊](https://steamcommunity.com/sharedfiles/filedetails/?id=2189392592) · [榜单](https://kovaaks.com/webapp-backend/leaderboard/scores/global?leaderboardId=666&page=0&max=1)|
|1w2ts reload smallflicks|121823|8 / 0.048|0.69°|[工坊](https://steamcommunity.com/sharedfiles/filedetails/?id=2112170820) · [榜单](https://kovaaks.com/webapp-backend/leaderboard/scores/global?leaderboardId=36&page=0&max=1)|
|Pasu Voltaic Reload Easy|39208|8 / 0.112|1.60°|[工坊](https://steamcommunity.com/sharedfiles/filedetails/?id=3645039165) · [榜单](https://kovaaks.com/webapp-backend/leaderboard/scores/global?leaderboardId=163323&page=0&max=1)|
|Air Voltaic Invincible 4 Easier|36317|5.2 / 0.095|2.09°|[工坊](https://steamcommunity.com/sharedfiles/filedetails/?id=3714529518) · [榜单](https://kovaaks.com/webapp-backend/leaderboard/scores/global?leaderboardId=185406&page=0&max=1)|
|Smoothsphere Viscose|36043|4.4 / 0.078|2.03°|[工坊](https://steamcommunity.com/sharedfiles/filedetails/?id=3711135549) · [榜单](https://kovaaks.com/webapp-backend/leaderboard/scores/global?leaderboardId=184106&page=0&max=1)|

## 已核对的机制与估算边界

- 六靶静态定位。历史同名配置为六靶、一击一分、三发弹匣、0.1 秒射击间隔和 0.5 秒空仓恢复。模拟在 7.8 × 2.8 米平面连续采样，避开邻靶与上一命中点。
- 双靶微调。同名配置为二靶，击杀补弹。为保留短距修正，在 1.58 × 0.94 米范围内，以另一靶为中心按面积抽样 0.22～0.95 米的短距偏移。半径与屏幕角尺寸尚待原版画面标定。
- Pasu 动态点击。工坊确认击杀补弹并取消命中率平方根乘数，公开样本中 171 杀对应 171 分。本地五个靶独立抽取转向时刻、转角，在平面上加速与折返。靶数、速度、边界和换向概率为估值。
- Air 反应跟枪。采用可越过水平线的无敌飞行靶。公开成绩 96.731% 伤害命中率对应 5800 分，近似采用满在靶每秒 100 分。模拟短横移、随机反向、深度和垂直扰动。加速度 27 米/秒²、0.14～0.66 秒的换向间隔待标定。
- Smoothsphere 平滑跟枪。工坊描述为变距、变速、轻跳的小型环绕靶。公开成绩 91.034% 伤害命中率对应 16389 分，本地使用满在靶每秒 300 分。角速、径向速度和高度变化由随机目标速度驱动并限加速度。

跟枪以 240 Hz 累加实际按住射击且射线在靶的时间。命中球半径与绘制直径共用数据。缺少同版本的录像角度标定、原版轨迹分布对照及高刷硬件端到端验证。

[Voltaic S2 目录](https://voltaic.gg/benchmarks/viscose_benchmarks_s2) · [静态项目历史配置](https://github.com/fvolpe83/Scenarios)
