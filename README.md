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

- 这里的安装脚本是学习和自用的，参照了大神cmliu, gshtwy的代码，安装三个节点，可全部安装也可单一安装。

- **搭建准备**
  
  - 在cloudflare上新建一个tunnel，记录token和域名
  
  - Serv00服务面板登录，开启端口，两个TCP和一个UDP
  
  - Serv00服务面板上设置允许外部程序运行

- **安装指令**

```
bash <(curl -s https://raw.githubusercontent.com/sunbonoy/serv00-projects/main/serv00-argo-s5-hy.sh)
```

- Serv00杀进程厉害，特别是明显特征的程序，所有这些程序都改名运行了；并且需要增加进程检测保活脚本。

- 进程检测保活脚本：[check-process.sh](https://github.com/sunbonoy/serv00-projects/blob/main/check-process.sh)，供参考；需要添加进定时任务内，比如每小时运行；可在Serv00服务面板上添加，也可`crontab -e`直接编辑添加任务。
