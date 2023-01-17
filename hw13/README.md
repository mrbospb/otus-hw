# Description
Настроить дашборд с 4-мя графиками (память, процессор, диск, сеть) на системе Prometheus-Grafana.
# How-to
Склонировать репозиторий на хост.

Поднять контейнеры:
```
[root@hw13 hw13]# docker-compose up -d
```
Проверить работу контейнеров:
```
[root@hw13 etc]# docker ps
CONTAINER ID   IMAGE                       COMMAND                  CREATED         STATUS         PORTS                                       NAMES
6c274ba99608   prom/node-exporter:v1.5.0   "/bin/node_exporter …"   2 minutes ago   Up 2 minutes   0.0.0.0:9100->9100/tcp, :::9100->9100/tcp   node-exporter
4c54fcd7a281   grafana/grafana:9.3.2       "/run.sh"                4 minutes ago   Up 4 minutes   0.0.0.0:3000->3000/tcp, :::3000->3000/tcp   grafana
a0d4887ca2bb   prom/prometheus:v2.41.0     "/bin/prometheus --c…"   4 minutes ago   Up 4 minutes   0.0.0.0:9090->9090/tcp, :::9090->9090/tcp   prometheus
```
Проверить работу сервисов по адресам:
* `http://{host_ip}:9090`     Prometheus
* `http://{host_ip}:3000`     Grafana
* `http://{host_ip}:9100`     Node exporter
В настройках Grafana в разделе Data sources добавить Prometheus, указав URL `http://prometheus:9090`.

Создать собственный дашборд или воспользоваться уже готовыми шаблонами с официального сайта (Grafana)[https://grafana.com/grafana/dashboards/]
# Log
## Собрать свой пакет
### Заходим на server
