# Serv00-projects

在Serv00上搭建了一些项目，参考并学习了很多大神的代码，自己做了一些记录，分享一下。

## Cloudflared执行文件

Serv00上运行Cloudflared需要FreeBSD系统的文件，但源文件的[下载地址](https://cloudflared.bowring.uk/binaries/)被禁止了，这里放置了备份文件下载。

- 版本 8.3，下载指令

```
curl -sL https://github.com/sunbonoy/serv00-projects/raw/main/cloudflared/cloudflared-freebsd-2024.8.3.7
```

- 搭建方法可看我的博客文章[**《学习笔记—Serv00搭建2》**](https://boblog.us.kg/post/xue-xi-bi-ji--Serv00-da-jian-2.html)



## Argo-Socks5-Hysteria2的搭建

- 在Serv00上使用一般vless, vlmess, trojan节点体验不好，速度也不快，即便套优选。开argo隧道后，效果要好很多，比较推荐。

- Serv00提供UDP端口，因而Hysteria2的搭建就简单了，速度提升也是明显的。

- Serv00的IP地址还是挺干净的，可访问ChatGPT和奈飞，作为私有的socks5代理算是一个小福利。

- 这里的安装脚本是学习和自用的，参照了大神cmliu, gshtwy的代码，安装三个节点，可全部安装也可单一安装。安装代码：

```
bash <(curl -s https://raw.githubusercontent.com/sunbonoy/serv00-projects/main/serv00-argo-s5-hy.sh)
```

- Argo隧道的vmess+ws节点，和Socks5都使用官方Xray内核运行，如果想要argo运行其它节点，如vless, trojan请在搭建后自行修改config.json的节点配置。在Xray官方项目内提供各种节点模板，可以参考设置。

- Hysteria2节点是自签域名的节点，使用官方内核程序运行。

- Serv00杀进程厉害，特别是明显禁止程序，所有这些程序都改名运行了；并且需要增加进程检测保活脚本。
