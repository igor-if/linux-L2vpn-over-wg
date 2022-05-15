#Установка wireguard:
	apt install wireguard

#Генерируем ключи:
	wg genkey | sudo tee client_private.key 
	wg pubkey | sudo tee client_public.key

#Создаем конфиг wireguard на клиенте:
#	vim /etc/wireguard/wg0.conf
cat << EOF > /etc/wireguard/wg0.conf
[Interface]
Address = 10.0.0.2/24
PrivateKey = GNpXCXcgjDZov9xzFtoEFxFXYGrLvk/9IpoUklzlP3k= # подставляем значение своего ключа
PostUp = /home/user/interfaces.sh
[Peer]
AllowedIPs = 0.0.0.0/0
PublicKey = xR4iLsoLOGJGWHzsQTFSmdr7W9c6VuBdFzSYgHFHwwI= # подставляем значение своего ключа
Endpoint = 192.168.1.207:51820
PersistentKeepalive = 30
EOF

#Запускаем wireguard с нашим конфигом:
	wg-quick up /etc/wireguard/wg0.conf

#Проверяем статус:
#	wg show

exit 0
