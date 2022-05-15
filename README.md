# net-en
Данный проект реализует одну из простых возможностей предоставления безопасного L2vpn между 2 linux серверами через недоверенную среду, такую как Internet. 
Настройка выполняется используя:
- Ubuntu 20.04
- wireguard
- iproute2

Тестирование выполняется с использованием утилит:
ping
iperf(v2)

Настройка:
1. Установлены 2 VM Ubuntu 20.04

2. Установка необходимых пакетов:

`apt install wireguard iperf `
    
3. Добавление конфигурационного файла на сервере wireguard:
```
vim /etc/wireguard/wg0.conf
[Interface] 
Address = 10.0.0.1/24 # локальный адрес wg interface
PrivateKey = +Na26xq1Uvb0DrKNZG53ZzEhP+2FMx3FcWIrILvjSH4= # приватный ключ сервера 
ListenPort = 51820 # порт сервера на котором ожидается соединение
[Peer]
PublicKey = s0snCNBFk0YDIlSbGof/ye5MJrYxh19veZlm5OVCHB0= # открытый ключ клиента
AllowedIPs = 0.0.0.0/0 # разрешенные ip клиентов 
```


4. Добавление конфигурационного файла для клиента wireguard:
```
vim /etc/wireguard/wg0.conf
[Interface]
Address = 10.0.0.2/24 # локальный адрес wg interface
PrivateKey = GNpXCXcgjDZov9xzFtoEFxFXYGrLvk/9IpoUklzlP3k= # приватный ключ клиента
[Peer]
AllowedIPs = 0.0.0.0/0  # разрешенные ip 
PublicKey = xR4iLsoLOGJGWHzsQTFSmdr7W9c6VuBdFzSYgHFHwwI= # открытый ключ сервера
Endpoint = 192.168.1.207:51820 # адрес сервера
PersistentKeepalive = 30
```

5. Запускаем wireguard и проверяем состояние:

на сервере и клиенте выполняем поднятие wg:

```
wg-quick up /etc/wireguard/wg0.conf
```
     
Проверяем состояние на клиенте:

```
wg show
interface: wg0
  public key: s0snCNBFk0YDIlSbGof/ye5MJrYxh19veZlm5OVCHB0=
  private key: (hidden)
  listening port: 32948

peer: xR4iLsoLOGJGWHzsQTFSmdr7W9c6VuBdFzSYgHFHwwI=
  endpoint: 192.168.1.207:51820
  allowed ips: 10.0.0.1/32
  latest handshake: 16 seconds ago
  transfer: 3.08 KiB received, 18.25 KiB sent
  persistent keepalive: every 5 seconds
```
   
Видим, что появился пир и трафик проходит в обе стороны.
   
6. Поднимаем алиасы на lo интерфейсах и добавялем статические маршруты до lo адресов соседа через wg туннель:

сервер:

```
ip address add 10.10.10.1/32 dev lo:1
ip route add 10.10.10.2/32 via 10.0.0.2
```
клиент:

```
ip address add 10.10.10.2/32 dev lo:1
ip route add 10.10.10.1/32 via 10.0.0.1
```
      
Проверяем доступность с клиента:

```
root@vm2client:/home/user# ping 10.10.10.1
PING 10.0.0.1 (10.0.0.1) 56(84) bytes of data.
64 bytes from 10.0.0.1: icmp_seq=1 ttl=64 time=1.37 ms
64 bytes from 10.0.0.1: icmp_seq=2 ttl=64 time=0.761 ms
64 bytes from 10.0.0.1: icmp_seq=3 ttl=64 time=0.601 ms
^C
--- 10.0.0.1 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2011ms
rtt min/avg/max/mdev = 0.601/0.911/1.373/0.332 ms
```
        
 7. Поднимаем L2tp интерфейс на сервере и клиенте:

Сервер:

```
root@server:/home/user# ip l2tp add tunnel remote 10.10.10.2 local 10.10.10.1 tunnel_id 10 peer_tunnel_id 10 encap ip
root@server:/home/user# ip l2tp add session tunnel_id 10 session_id 10 peer_session_id 10
root@server:/home/user# ip link set l2tpeth0 up
```
      
Клиент:

```
root@vm2client:/home/user# ip l2tp add tunnel remote 10.10.10.1 local 10.10.10.2 tunnel_id 10 peer_tunnel_id 10 encap ip
root@vm2client:/home/user# ip l2tp add session tunnel_id 10 session_id 10 peer_session_id 10
root@vm2client:/home/user# ip link set l2tpeth0 up
```
      
8. добавляем vlan интерфейс и добавляем L2 связность между L2tp и vlan используя bridge интерфейс:
На сервере и клиенте:
Добавляем vlan:

```
ip link add link ens37 name vlan10 type vlan id 10
ip link set vlan10 up
```
Добавляем bridge и добавляем slave интерфейсы в bridge:

```
ip link add br0 type bridge
ip link set vlan10 master br0
ip link set l2tpeth0 master br0
ip link set br0 up
```

9. добавляем ip адреса для master интерфейсов и делаем проверку:

Сервер:

```
ip add add 172.16.0.1/30 dev br0
```
Клиент:

```
ip add add 172.16.0.2/30 dev br0
```
    
Проверка icmp:

```
root@server:/home/user# ping 172.16.0.2
PING 172.16.0.2 (172.16.0.2) 56(84) bytes of data.
64 bytes from 172.16.0.2: icmp_seq=1 ttl=64 time=1.09 ms
64 bytes from 172.16.0.2: icmp_seq=2 ttl=64 time=0.414 ms
^C
--- 172.16.0.2 ping statistics ---
**2 packets transmitted, 2 received, 0% packet loss, time 1002ms**
rtt min/avg/max/mdev = 0.414/0.752/1.091/0.338 ms
```
      
Проверяем arp таблицу:

```
root@server:/home/user# ip nei
192.168.1.43 dev ens33 lladdr e8:9e:b4:51:aa:aa REACHABLE
192.168.1.209 dev ens33 lladdr 00:0c:29:28:2d:c5 REACHABLE
**172.16.0.2 dev l2tpeth0 lladdr 0e:27:3f:c6:c3:2a REACHABLE**
192.168.1.1 dev ens33 lladdr fc:ec:da:72:aa:aa STALE
```

Тест скорости с помощью iperf:

Запускаем iperf server на клиенте:

```
iperf -s
```
На сервере запускаем тест:

```
root@server:/home/user# iperf -c 172.16.0.2 -t 60 -i 10 -b
------------------------------------------------------------
Client connecting to 172.16.0.2, TCP port 5001
TCP window size: 85.5 KByte (default)
------------------------------------------------------------
[  3] local 172.16.0.1 port 49702 connected with 172.16.0.2 port 5001
[ ID] Interval       Transfer     Bandwidth
0.0-10.0 sec   221 MBytes   186 Mbits/sec
[  3] 10.0-20.0 sec   356 MBytes   299 Mbits/sec
[  3] 20.0-30.0 sec   342 MBytes   287 Mbits/sec
[  3] 30.0-40.0 sec   327 MBytes   275 Mbits/sec
[  3] 40.0-50.0 sec   261 MBytes   219 Mbits/sec
[  3] 50.0-60.0 sec   267 MBytes   224 Mbits/sec
**0.0-60.0 sec  1.73 GBytes   248 Mbits/sec**
```

![iperf] (https://drive.google.com/file/d/1hpx0hyNIn5sC5KC6qAbeinrb7ELfz05L/view?usp=sharing "iperf")
![interfaces] (https://drive.google.com/file/d/1m8zY38fyF3vK85WFOmzxOwKDJohxMw25/view?usp=sharing "interfaces")

        
