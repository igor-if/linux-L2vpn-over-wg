#!/bin/bash

#Добавляем адреса на lo:
ip addr add $loip dev $lo

#Добавляем маршрут до lo интерфейса клиента:
ip route add $peerlo via 10.0.0.2

#Создаем l2tp тунель, сессию и поднимаем интерфейс:
ip l2tp add tunnel remote 10.10.10.2 local 10.10.10.1 tunnel_id 10 peer_tunnel_id 10 encap ip
ip l2tp add session tunnel_id 10 session_id 10 peer_session_id 10
ip link set l2tpeth0 up mtu 1500

#Создаем vlan interface:
ip link add link ens37 name vlan10 type vlan id 10
ip link set vlan10 up

#Создаем мост и объединяем интерфейсы:
ip link add name br0 type bridge
ip link set dev br0 up promisc on
ip link set dev l2tpeth0 master br0
ip link set dev vlan10 master br0

#Добавляем ip address на bridge:
ip add add 172.16.0.1/30 dev brs0