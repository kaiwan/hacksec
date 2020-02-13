**IoT Security - a brief Presentation**

- [Overview of the Most Popular Smart Home Devices](http://iotlineup.com/)  
- IoT search engines : [shodan.io](https://www.shodan.io/), [thingful.net](http://www.thingful.net/)


- A huge ecosystem
	- we only talk about security from the developer / code viewpoint; and within that, Linux systems and kernel programming

- Real-world Hacks
	- websites, hacks  

- Walk-through a slide deck on 
	- Terminology
	- Current State
		- 'Security Vulnerabilities in Modern OS's', Cisco
	- BoF : a few 'famous' exploits
	- IoT attacks in the real world - a few 'famous' exploits
	- BoF (Buffer Overflow)
		- Tech Preliminaries - the process VAS
			- *vasu_grapher* visualization util
			- process stack
			- a simple BoF
				- the danger
	- Demo on the Raspberry Pi 3
		- BoF address re-vectoring with GDB
		- a simplistic kernel exploit (via mmap) - eg. of a privilege escalation (privesc) attack
	- Modern OS Hardening / Countermeasures

<hr>
**A few tools : summary**  
	- github.com/kaiwan  
	
  * - [vasu_grapher](https://github.com/kaiwan/vasu_grapher)   [under dev]  
		- [stanly](https://github.com/kaiwan/stanly), [cquats](https://github.com/kaiwan/cquats) [under dev]
	- Static Analysis
		- commercial:
		     - SonarQube / [SonarCloud](https://sonarcloud.io/about) (free for OSS!)
		     - Coverity, Klocwork, ...
		- free and OSS:
		      - coccinelle, D Wheeler's [flawfinder](), smatch, cppcheck, etc
	- [lynis](https://cisofy.com/downloads/lynis/), [checksec.sh](https://github.com/slimm609/checksec.sh), ...
	- [GDB Enhanced Features (a.k.a. GEF)](https://github.com/hugsy/gef)
	- IoT search engines (shodan.io, thingful.net)

<hr>
*Real-world Hacks*

- _[IoT Security Wiki : One Stop for IoT Security Resources](https://iotsecuritywiki.com/)_
Huge number of resources (whitepapers, slides, videos, etc) on IoT security

_Hacks_

- US-CERT_ [_Alert (TA16-288A) - Heightened DDoS Threat Posed by Mirai and Other Botnets_](https://www.us-cert.gov/ncas/alerts/TA16-288A)
*"_On September 20, 2016, Brian Krebs’ security blog (krebsonsecurity.com) was targeted by a massive DDoS attack, one of the largest on record, exceeding 620 gigabits per second (Gbps).[[1](https://krebsonsecurity.com/2016/09/krebsonsecurity-hit-with-record-ddos/)] An IoT botnet powered by Mirai malware created the DDoS attack. The Mirai malware continuously scans the Internet for vulnerable IoT devices, which are then infected and used in botnet attacks. The Mirai bot uses a short list of 62 common default usernames and passwords to scan for vulnerable devices. Because many IoT devices are unsecured or weakly secured, this short dictionary allows the bot to access hundreds of thousands of devices.[[2](https://nakedsecurity.sophos.com/2016/10/05/mirai-internet-of-things-malware-from-krebs-ddos-attack-goes-open-source/)] The purported Mirai author claimed that over 380,000 IoT devices were enslaved by the Mirai malware in the attack on Krebs’ website.[\[3\]](https://www.pcworld.com/article/3126362/security/iot-malware-behind-record-ddos-attack-is-now-available-to-all-hackers.html))]

 *In late September, a separate Mirai attack on French webhost OVH broke the record for largest recorded DDoS attack. That DDoS was at least 1.1 terabits per second (Tbps), and may have been as large as 1.5 Tbps.[[4](http://arstechnica.com/security/2016/09/botnet-of-145k-cameras-reportedly-deliver-internets-biggest-ddos-ever/)] ...”*

- Insecure, weak passwords, see this:
 https://github.com/lcashdol/IoT/blob/master/passwords/list-2019-01-29.txt
 
- [Hacking DefCon 23’s IoT Village Samsung fridge](https://www.pentestpartners.com/security-blog/hacking-defcon-23s-iot-village-samsung-fridge/),_ _Aug 2015 (DefCon 23)_

- [HACKING IoT: A Case Study on Baby Monitor Exposures and Vulnerabilities](https://www.rapid7.com/docs/Hacking-IoT-A-Case-Study-on-Baby-Monitor-Exposures-and-Vulnerabilities.pdf)

“_... these devices are marketed and treated as if they are single purpose devices, rather than the general purpose computers they actually are. ..._
_..._
_IoT devices are actually general purpose, networked computers in disguise, running reasonably complex network-capable software. In the field of software engineering, it is generally believed that such complex software is going to ship with exploitable bugs and implementation-based exposures. Add in external components and dependencies, such as cloud-based controllers and programming interfaces, the surrounding network, and other externalities, and it is clear that vulnerabilities and exposures are all but guaranteed.”_
*<< See pg 6, ‘Ch 5: COMMON VULNERABILITIES AND EXPOSURES FOR IoT DEVICES’ ; old and new vulnerabilities mentioned.
Pg 9: ‘Disclosures’ - the vulns uncovered in actual products >>*

IOT SECURITY: HARD PROBLEM, NO EASY ANSWERS Fahmida Y. Rashid](https://duo.com/decipher/iot-security-hard-problem-no-easy-answers)

_**Just too much; the Bottom Line:   
It's critical to perform adequate pentesting – either outsource or DIY.**_
<hr>
In general, defeating low-level hardening on x86:  
 ['Linux (x86) Exploit Development Series, sploitfun'](https://sploitfun.wordpress.com/2015/06/26/linux-x86-exploit-development-tutorial-series/)  

*Writing Kernel Exploits*

- ["Kernel Driver mmap Handler Exploitation" \[PDF\]](https://labs.mwrinfosecurity.com/assets/BlogFiles/mwri-mmap-exploitation-whitepaper-2017-09-18.pdf)
- ["Exploiting Stack Overflows in the Linux Kernel" [PDF]](https://www.exploit-db.com/docs/english/15634-exploiting-stack-overflows-in-the-linux-kernel.pdf)
- ... many more; many, many here: ["Linux Kernel Exploitation"](https://github.com/xairy/linux-kernel-exploitation)

<hr>
[My (Kaiwan NB) tech blog; do subscribe! :-)](https://kaiwantech.wordpress.com/)
