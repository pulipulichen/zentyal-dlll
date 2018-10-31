Network IP range
=======

# Virtual Machine

## For VMID: 100~999
- Example VMID: 105
- Example IP: 10.0.1.5
	- Part A: 10 (fixed)
	- Part B: 0 (fixed)
	- Part C: 1, 1~9 (VMID 1nd number)
	- Part D: 5 (=05), 1~99 (VMID 2nd & 3rd number)
- Ports:
	- Pound: 105**0**
	- HTTP: 105**8**
	- HTTPS: 105**3**
	- SSH: 105**2**
	- RDP: 105**9**

## For VMID: > 1000
- Example VMID: 1055
- Example IP: 10.1.0.55
	- Part A: 10 (fixed)
	- Part B: 1, 1~5 (VMID 1st number)
	- Part C: 0 (VMID 2nd number)
	- Part D: 55, 1~99 (VMID 3rd & 4th number)
- Ports:
	- Pound: 1055**0**
	- HTTP: 1055**8**
	- HTTPS: 1055**3**
	- SSH: 1055**2**
	- RDP: 1055**9**

## DHCP Range for virtual machines
- IP range: 10.6.2.1 - 10.6.2.254

<del>DHCP for temporary virtual machines: 10.254.0.1 - 10.254.255.254</del>

----------


# Virtual Environment Server (Proxmox)
- Example IP: 10.6.0.55
- The 1st part should be 10, 
- the 2nd part should be 6, 
- the 3rd part should be 0, and 
- the 4th part should be between 1~99.
	- 1~9: master series
	- 11~19: slave series
	- 21~29: rack series
# Storage Servers:
- Example IP: 10.6.1.4
- The 1st part should be 10, 
- the 2nd part should be 6, 
- the 3rd part should be 1, and 
- the 4th part should be between 1~99.
