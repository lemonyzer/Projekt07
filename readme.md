# Playstation 2 Controller (Digital & Analog) am PIC16F84A 
## mit Zustandsausgabe über MAX7219 LED-Matrix 

### Videos
[![Projekt07 - PS2 Controller @ PIC16F84A with MAX7219](https://img.youtube.com/vi/H5jBCrzZ8P4/0.jpg)](https://www.youtube.com/embed/H5jBCrzZ8P4?mute=1;autoplay=1)
[![Projekt07 - PS2 Controller @ PIC16F84A](https://img.youtube.com/vi/TfXMUS_N8tY/0.jpg)](https://www.youtube.com/embed/TfXMUS_N8tY?mute=1;autoplay=1)

### PlayStation 2 Controller
<p>
    <img src="/assets/pinout ps2 controller.jpg" width="400" height="328"><br><br>
    <ol>
        <li><p style="margin-bottom: 0cm; text-decoration: none;"><b><font color="#ff0000">(Ausgang)</font>	<font color="#00ff00">DATA</font></b>, 8-bit, serieller Transfer</p>
            <p style="margin-bottom: 0cm; text-decoration: none;">-bei negativer	Flanke von CLOCK</p></li>
        <li><p style="margin-bottom: 0cm; text-decoration: none;"><b><font color="#ff0000">(Eingang)</font>	<font color="#b3b3b3">COMMAND</font></b>, 8-bit, serieller Transfer</p>
            <p style="margin-bottom: 0cm; text-decoration: none;">-bei negativer	Flanke von CLOCK</p></li>
        <li><p style="margin-bottom: 0cm; text-decoration: none;"><i>Nicht	belegt</i></p></li>
        <li><p style="margin-bottom: 0cm; text-decoration: none;"><b>(Eingang)	<font color="#280099">GND</font> - </b>Pin an Masse</p></li>
        <li><p style="margin-bottom: 0cm; text-decoration: none;"><b>(Eingang)	<font color="#ffff00">VCC</font> - </b>Pin zur +5V Spannungsquelle</p></li>
        <li><p style="margin-bottom: 0cm; text-decoration: none;"><b><font color="#ff0000">(Eingang)</font>	<font color="#ff0000">ATT</font> -</b> bevor der Controller Daten	erhält, muss hier 0V (Masse) anliegen.</p></li>
        <li><p style="margin-bottom: 0cm; text-decoration: none;"><b><font color="#ff0000">(Eingang)</font>	CLOCK -</b> zur synchronisierten Übertragung</p></li>
        <li><p style="margin-bottom: 0cm; text-decoration: none;"><i>Nicht	belegt</i></p></li>
        <li><p style="margin-bottom: 0cm; text-decoration: none;"><b>(Ausgang)	<font color="#cc6633">ACK</font> - </b>sendet ein Signal, wenn ein	Befehl an Pin 2 angekommen ist</p></li>
    </ol>
    <p style="margin-bottom: 0cm; text-decoration: none;"><font color="#ff0000"><b>ROT</b><font color="#000000"> markierte Ein- oder Ausgänge sind direkt am PIC angeschlossen.</font></font></p>
    <p style="margin-bottom: 0cm; text-decoration: none;"><br></p>
</p>

### Schaltplan
   ![Schaltplan](/assets/schaltplan.png)

### Platinen Layout
   ![Layout Top](/assets/board_layout_top.png)
   ![Layout Bottom](/assets/board_layout_bottom.png)

### Bestückungsplan
   ![Bestückungsplan](/assets/bestückungsplan.png)



### Flowcharts
<details> 
  <summary>V5: Flowcharts aus der Dokumentation </summary>
   <p>
        <img src="/Flowcharts/vDoku/1main.jpg" alt=""> 
        <img src="/Flowcharts/vDoku/UP_PSC_sende_tabelle.jpg" alt=""> 
        <img src="/Flowcharts/vDoku/UP_MAX_sende_tabelle.jpg" alt=""> 
        <img src="/Flowcharts/vDoku/UP_Display.jpg" alt=""> 
    </p>
</details>

<details> 
  <summary>V4: Flowcharts </summary>
   <p>
        <img src="/Flowcharts/v41/1main.jpg" alt=""> 
        <img src="/Flowcharts/v41/2Start.jpg" alt=""> 
        <img src="/Flowcharts/v41/3Get_Type.jpg" alt=""> 
        <img src="/Flowcharts/v41/3Get_Type.jpg" alt=""> 
        <img src="/Flowcharts/v41/4Get_Status.jpg" alt=""> 
        <img src="/Flowcharts/v41/5Get_L_btns.jpg" alt=""> 
        <img src="/Flowcharts/v41/6Get_R_btns.jpg" alt=""> 
        <img src="/Flowcharts/v41/7Get_R_Joy_x.jpg" alt=""> 
        <img src="/Flowcharts/v41/8Get_R_Joy_y.jpg" alt=""> 
        <img src="/Flowcharts/v41/9Get_L_Joy_x.jpg" alt=""> 
        <img src="/Flowcharts/v41/10Get_L_Joy_y.jpg" alt="">
    </p>
</details>

