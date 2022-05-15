#Установка wireguard:
	apt install wireguard
#Генерируем ключи:

   	wg genkey | sudo tee server_private.key 
	wg pubkey | sudo tee server_public.key

#Создаем конфиг wireguard на сервере:
#	vim /etc/wireguard/wg0.conf

cat << EOF > /etc/wireguard/wg0.conf
[Interface] 
Address = 10.0.0.1/24 
PrivateKey = +Na26xq1Uvb0DrKNZG53ZzEhP+2FMx3FcWIrILvjSH4= # подставляем значение своего ключа
ListenPort = 51820
PostUp = /home/user/interfaces.sh
[Peer]
PublicKey = s0snCNBFk0YDIlSbGof/ye5MJrYxh19veZlm5OVCHB0= # подставляем значение своего ключа
AllowedIPs = 0.0.0.0/0 
EOF

#Запускаем wireguard с нашим конфигом:
	wg-quick up /etc/wireguard/wg0.conf

#Проверяем статус:
#wg show

exit 0