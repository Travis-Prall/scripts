##################################################################################
#                              Author: Travis Prall                              #
#                     Creation Date: July 17, 2022 01:32 PM                      #
#                     Last Updated: August 7, 2022 11:27 AM                      #
#                          Source Language: shellscript                          #
#                                                                                #
#                            --- Code Description ---                            #
#                  Iptables nat routing to control DNS queries                   #
##################################################################################



#!/bin/bash



iptables -t nat -A PREROUTING -s 192.168.2.0/24 ! -d 192.168.1.0/24 -p tcp --dport 53 -j DNAT --to-destination 192.168.1.39-192.168.1.40
iptables -t nat -A PREROUTING -s 192.168.2.0/24 ! -d 192.168.1.0/24 -p udp --dport 53 -j DNAT --to-destination 192.168.1.39-192.168.1.40
iptables -t nat -A PREROUTING -s 192.168.3.0/24 ! -d 192.168.1.0/24 -p tcp --dport 53 -j DNAT --to-destination 192.168.1.39-192.168.1.40
iptables -t nat -A PREROUTING -s 192.168.3.0/24 ! -d 192.168.1.0/24 -p udp --dport 53 -j DNAT --to-destination 192.168.1.39-192.168.1.40
iptables -t nat -A PREROUTING -s 192.168.10.0/24 ! -d 192.168.1.0/24 -p tcp --dport 53 -j DNAT --to-destination 192.168.1.39-192.168.1.40
iptables -t nat -A PREROUTING -s 192.168.10.0/24 ! -d 192.168.1.0/24 -p udp --dport 53 -j DNAT --to-destination 192.168.1.39-192.168.1.40

