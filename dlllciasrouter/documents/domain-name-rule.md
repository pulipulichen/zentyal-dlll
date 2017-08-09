Domain Name Rule
=======

## Format

Domain Name Section Format:

**"<font color="#9b00d3">[type]</font>-<font color="#0000ff">[name]</font>-<font color="#8fb08c">[year]</font>.<font color="#f79646">[upper-domain-name]</font>"**

For example:

**"<font color="#9b00d3">test</font>-<font color="#0000ff">zentyal</font>-<font color="#8fb08c">2013</font>.<font color="#f79646">dlll.nccu.edu.tw</font>"**

## Section

### <font color="#9b00d3">[type]</font>

Usage.

*   **exp** (experiment): for 1 semester.   
    <font color="#9b00d3">**exp**</font>-kals-2012.dlll.nccu.edu.tw
*   **test**: discard in anytime.  
    <font color="#9b00d3">**test**</font>-pudding-2013.dlll.nccu.edu.tw
*   **pc** (personal computer): for 3 years.  
    <font color="#9b00d3">**pc**</font>-pudding-2013.dlll.nccu.edu.tw
*   **teach**: for 1 semester.  
    **<font color="#9b00d3">teach</font>**-dspace-dlll-2013.dlll.nccu.edu.tw
*   **demo**: for a long time  
    **<font color="#9b00d3">demo</font>**-kals-2013.dlll.nccu.edu.tw
*   **public**: for a long time.  
    **<font color="#9b00d3">public</font>**-kals-2013.dlll.nccu.edu.tw
*   **(non-type)**: equal to type public, for a long time.  
    reading-club-2013.dlll.nccu.edu.tw  

### <font color="#0000ff">[name]</font>

Project name or user’s name.

*   **<font color="#0000ff">kals</font>**: a project name.  
    demo-<font color="#0000ff">**kals**</font>-2009.dlll.nccu.edu.tw  

*   **<font color="#0000ff">dspace-dlll</font>**: a project name.  
    demo-<font color="#0000ff">**dspace-dlll**</font>-2013.nccu.edu.tw  

*   **<font color="#333333">dspace-dlll-01</font>**: a project name for group 01.  
    teach-<font color="#0000ff">**dspace-dlll-01**</font>-2013.dlll.nccu.edu.tw
*   <font color="#0000ff">**pudding**</font>: a user name.  
    pc-<font color="#0000ff">**pudding**</font>-2013.dlll.nccu.edu.tw
*   **<font color="#0000ff">red</font>**: a user name.  
    pc-<font color="#0000ff">**red**</font>-2012.dlll.nccu.edu.tw

### <font color="#8fb08c">[year]</font>

Created year.

*   <font color="#8fb08c">**2012**</font>: Created from 2012.  
    pc-red-<font color="#9bbb59">**2012**</font>.dlll.nccu.edu.tw
*   <font color="#8fb08c">**2013**</font>: Created from 2013.  
    demo-dspace-dlll-<font color="#8fb08c">**2013**</font>.nccu.edu.tw  

### <font color="#f79646">[upper-domain-name]</font>

Domain name which DNS could control.

*   **<font color="#f79646">dlll.nccu.edu.tw</font>**: for DLLL LAB use.  
    teach-dspace-dlll-01-2013.<font color="#f79646">**dlll.nccu.edu.tw**  
    </font>
*   **<font color="#f79646">lias.nccu.edu.tw</font>**: for LIAS use.  
    teach-koha-2013.**<font color="#f79646">lias.nccu.edu.tw</font>**

----

## Domain Name(網址)申請原則

#### lias.nccu.edu.tw 網域底下的網址格式

這部份歸屬圖檔所，由助教管理(我希望如此)。請依照老師、助教的要求來設定。供圖檔所、研討會、教學、圖檔所學生使用。

一般實驗室成員在做實驗、測試時，請勿使用lias.nccu.edu.tw網址。

#### dlll.nccu.edu.tw 網域底下的網址格式

網址與虛擬主機的hostname的格式盡量以以下的形式來設定：

<span style="color: #0000ff;">[服務類型代號]-[服務名稱]-[副本編號]-[建立年份].dlll.nccu.edu.tw</span>

舉例來說，KALS標註系統的服務類型為「公開服務」(設為public)，服務名稱為「kals」，建立年份為「2011」年的服務，則網址為「public-kals-2011.dlll.nccu.edu.tw」。

如果服務名稱難以決定，那麼就以申請者的e-mail名稱為主。例如「demo-yenchang-2011」。

如果是做成集叢(cluster)，則以VMID編號，例如exp-kals-moodle-134-2014

#### 依照服務類型，分成以下類別：

<table style="border: 5px  height: 100%; width: 100%;" frame="border" rules="all" align="left">

<tbody>

<tr>

<td>服務類型</td>

<td>類型代號</td>

<td>使用時間</td>

<td>備份數量</td>

<td>用途</td>

</tr>

<tr>

<td>正式網址  
（部分屬於公開服務、部分屬於雲端平台）</td>

<td>(不加類型代號與年份)</td>

<td>永久</td>

<td>10</td>

<td>◇ 實驗室網站：dlll.nccu.edu.tw （公開服務）  
◇ DNS：dns.dlll.nccu.edu.tw （公開服務）  
◇ 實驗室FTP：ftp.dlll.nccu.edu.tw （雲端平台）  
◇ KM：km.dlll.nccu.edu.tw （雲端平台）<span style="color: #000000; font-family: Verdana, Arial, Helvetica, sans-serif; font-size: 11px;">  
</span></td>

</tr>

<tr>

<td>公開服務</td>

<td>public</td>

<td>長期</td>

<td>5</td>

<td>◇ 對實驗室以外的人提供的服務  
◇盡可能是完整的服務  
◇可能會有多個版本，所以要加上年份  
◇要留下聯絡方式</td>

</tr>

<tr>

<td>實驗服務</td>

<td>exp</td>

<td>短期(一年之內)</td>

<td>10</td>

<td>◇宣傳實驗網址時可以使用  
◇可能會快速改變、消失、不使用  
◇務必加入年份，區別版本</td>

</tr>

<tr>

<td>展示服務</td>

<td>demo</td>

<td>長期</td>

<td>5</td>

<td>◇論文完成之後的系統展示  
◇資料盡量不要改變，保持實驗完成的原貌  
◇作為往後學弟妹研究的系統基礎</td>

</tr>

<tr>

<td>教學服務</td>

<td>teach</td>

<td>短期(一學期)</td>

<td>10</td>

<td>◇供教學時方便讓人記得網址使用  
◇記得要加上年份，因為同一種教學方式可能會用在不同學期。</td>

</tr>

<tr>

<td>測試服務</td>

<td>test</td>

<td>非常短(數月內)</td>

<td>0</td>

<td>◇私人下測試用  
◇不使用的話記得一定要移除</td>

</tr>

<tr>

<td>個人使用</td>

<td>pc</td>

<td>短期(一到兩年)</td>

<td>0</td>

<td>◇ pc-red-201.dlll.nccu.edu.tw</td>

</tr>

<tr>

<td>雲端平台</td>

<td>cloud</td>

<td>長期服務</td>

<td>10</td>

<td>雲端平台使用的工具</td>

</tr>

<tr>

<td>範本</td>

<td>template</td>

<td>長期(平時關機)</td>

<td>0</td>

<td>製作其他網站樣板使用的類型</td>

</tr>

</tbody>

</table>