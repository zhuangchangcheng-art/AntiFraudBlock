# AntiFraudBlock（防反诈上报拦截）

KernelSU 模块，只做一件事：阻止本机向国家反诈平台与联通 SystemHelper 设备管理平台上报。

## 拦什么

- 域名：`fzpt.cn`、`gjfzpt.cn`、`chanct.cn` 及子域名，hosts 空解析到 `0.0.0.0` / `::`
- 域名：`dm.wo.com.cn`（联通 SystemHelper 设备管理上报），hosts 空解析到 `0.0.0.0` / `::`
- IP：215 个 IP（214 个国家反诈平台 IP + 1 个联通 DM IP），iptables 专用链 `ANTIFRAUD`，`REJECT`（不是 `DROP`，被拦的请求快速失败，不会让 App 卡住）

## 不做什么

- 不装 DNS 代理、不改任何 App 组件、不冻结组件、不联网拉取名单
- 卸载只删自己加的规则，其他什么都不动

## 安装

1. 如果装过旧的 AdGuardHome 模块，先卸载它
2. 把本仓库打成 zip（见下面打包方法），在 KernelSU 里安装
3. Hot Install，免重启，装完即生效；点模块的 Action 按钮可查看状态（hosts 是否生效、REJECT 规则数）

打包方法：

```sh
zip -r AntiFraudBlock-20261106-v2.zip action.sh block-ips.txt customize.sh hotinstall.sh module.prop service.sh uninstall.sh system/
```

## 局限

- hosts 只能精确匹配列出的域名，未列出的子域名靠 IP 层拦截
- `dm.wo.com.cn` 的 IP 是 2026-11-06 解析的快照（走 GSLB 可能轮换），拦它主要靠 hosts 层；且 SystemHelper 的服务器地址是可配置的，只拦默认地址不是万无一失，彻底的办法是卸载该组件
- 如果上报走运营商通道直传（不走 DNS、不走常规 IP），拦不住
- 拦截思路参考 [BaiLai7513/anti-fraud-ads](https://github.com/BaiLai7513/anti-fraud-ads)

## 版本

- v1（2026-11-03）：首版，hosts 11 个域名 + iptables 214 个 IP
- v2（2026-11-06）：新增 `dm.wo.com.cn`（联通 SystemHelper 上报），hosts 12 个域名 + iptables 215 个 IP
