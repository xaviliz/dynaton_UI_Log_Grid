
/* This is an static plot for Characteristic functions to create a prototype and later
 to define a class to manipulate the graphics 
 
 NOTE: This option is nice but grid shape takes so much computation
 better to use dynatonTest_UI_Log_Resolution and apply scaling over that object. */

Point a, b, diff;
int fs = 44100, fftSize = 8192;
int offset, offset2, x_range, widthOver2, heightOver2, up_vt_label, down_vt_label;
int nlines, step_6dBs, fmin, fmax, tras_x = 0, tras_y = 0;
int f_label[] = {20, 50, 100, 200, 500, 1000, 2000, 5000, 10000, 20000};
int down_bond = -60, up_bond = 18;
int mouseClickX = -100, mouseClickY = -100;
//double[] f = new double[1140];      // it should be defined without a specific size
// use ArrayList when dont know the size for this array
ArrayList<Double> ft = new ArrayList<Double>();   // replace f with ft use .add() and .get()
int line_grid_space = 6; // in dBs
PShape grid, frame;
PFont mono;
float zoom_x = 1.f, zoom_y = 1.f;

void setup()
{
  size(displayWidth, displayHeight, OPENGL);
  println("Display size: " + width + ", " + height);
  background(255);
  fill(0);
  
  offset = displayHeight / 12;
  offset2 = 2 * offset;
  heightOver2 = displayHeight / 2;
  widthOver2 = displayWidth / 2;
  // Frequency range parameters
  fmin = 20;
  fmax = 20000;
  // Read font
  mono = loadFont("AppleSDGothicNeo-UltraLight-18.vlw");
  textFont(mono);
  
  /* TODO Tasks
  1 - Print lines in grid - DONE
  2 - Print H(w) function -DONE
  3 - Create frame object - DONE
  4 - Limit zoom action - DONE
  5 - Apply translation when mouse is dragged inside display when zoom is higher than 1 - DONE
  5B - Generate constraints for tranlation based on zoom factor, it can be applied directly limiting 
  the traslation factor to widthOver2 and heightOver2
  6 - Compute nlines when zoom out is applied less than 1
  7 - Modify labels when zoom is done
  8 - Apply oversampling for frequencies lower than 1000Hz to reconstruct H(w)*/
  
  /* The order to draw correctly the display is: 
  0- Read H(w) and compute magnitude to pixel transformation
  1- draw grid, - DONE 
  2- draw frame, - DONE
  3- draw labels and axes
  4- draw and apply zoom buttons  - DONE*/
  
  // 0- Read H(w) and compute magnitude to pixel transformation
  a = new Point();
  b = new Point();
  a.set_pos(offset2, offset2);
  b.set_pos(displayWidth - (offset2), displayHeight - (offset2));
  double d = distBetweenPoints(a, b);
  // Initially, the display space can be divided in 78dB (-60 - 18 dBFS) 
  // Compute the pixels difference between boundaries
  Point diff = diffBetweenPoints(a, b);
  x_range = diff.x;
  // pixels per dB
  int pixPerdB = diff.x / (up_bond - down_bond);
  // how many lines fit the display space
  nlines = diff.x/(pixPerdB * line_grid_space);
  down_vt_label = offset2+diff.y;
  up_vt_label = offset2+offset/10;
  int pixelVertRange =  down_vt_label - (offset2+offset/8);
  step_6dBs = pixelVertRange / nlines;
  
  // 1- Draw grid
  grid = createShape();
  grid.beginShape(QUADS);        // If no mode is specified, the shape can be any irregular polygon
  grid.noStroke();  
  grid.fill(0);
  float dd = 1;        // define the width of quads
  // Fill grid pixels with white color
  for (int x = -widthOver2+offset2+1; x < widthOver2-offset2-1; x++) {
    for (int y = -heightOver2+offset2+1; y < heightOver2-offset2-1; y++) {
      grid.fill(255);//255 * noise(x, y));
      grid.attribPosition("tweened", x, y, 100 * noise(x, y));
      grid.vertex(x, y, 0);
     
      grid.fill(255);//255 * noise(x + d, y));
      grid.attribPosition("tweened", x + dd, y, 100 * noise(x + dd, y));
      grid.vertex(x + dd, y, 0);
      
      grid.fill(255);//255 * noise(x + d, y + d));
      grid.attribPosition("tweened", x + dd, y + dd, 100 * noise(x + dd, y + dd)); 
      grid.vertex(x + dd, y + dd, 0);
      
      grid.fill(255);//255 * noise(x, y + d));
      grid.attribPosition("tweened", x, y + dd, 100 * noise(x, y + dd));
      grid.vertex(x, y + dd, 0);
    }
  }
  // Draw grid
  for (int i = 1; i < nlines; i++) {
    // Draw horizontal dashed line - Grid - Now are continuous lines
    for(int x = -widthOver2+offset2+1; x < widthOver2-offset2-1; x = x+3) {
      int h = offset2+(i*(step_6dBs+1))-heightOver2;
      grid.fill(200); // print in black
      grid.vertex(x, h, 0);
      grid.vertex(x + dd, h, 0);
      grid.vertex(x + dd, h + dd, 0);
      grid.vertex(x, h + dd, 0);
    }
  } 
  // Print a green line - simple example
  for (int x = -widthOver2+offset2+1; x < widthOver2-offset2-1; x++) {
      grid.fill(100, 200, 0); // print in green
      // Line A
      grid.vertex(x, -24, 0);
      grid.vertex(x + dd, -24, 0);
      grid.vertex(x + dd, -24 + dd, 0);
      grid.vertex(x, -24 + dd, 0);
  }
  // Print - vertical lines  - frequency marks
  // Draw x-axis with Frequency in log way
  // f should be defined in terms of fs, fmin and fmax
  double b1 = Math.log(fmin)/Math.log(2);
  double b2 = Math.log(fmax)/Math.log(2);
  // define frequency in log2 range 
  double rb = b2 - b1;
  // define steps by display space resolution
  double log_step = (rb/x_range);//diff.x);
  double nf = b1;
  //f[]= new double[x_range];
  boolean cdn_draw = false;
  boolean cdn_label = false;
  textSize(18);
  // Process first mapped log frequency
  //f[0] = Math.pow(2,nf);
  ft.add(Math.pow(2,nf));
  nf = nf + log_step;
  
  // Draw the rest of frequency labels
  for(int i = 1; i<x_range;i++){
    //f[i] = Math.pow(2,nf);
    ft.add(Math.pow(2,nf));
    //println(f[i]+"Hz with pixel "+ i);
    // print frequencies <100Hz
    if (ft.get(i)<=100){
      if (ft.get(i-1)%10.>9.5 && ft.get(i)%10.<0.3){
        stroke(0);
        cdn_draw = true;
        if(ft.get(i)>45 && ft.get(i)<55)
          cdn_label = true;
      }
    }
    else{
      // print frequencies >100Hz and <1kHz
      if (ft.get(i)<1000){
        if (ft.get(i-1)%100.>90 && ft.get(i)%100.<5){
          cdn_draw = true;
          for (int j = 0; j<3; j++)
            if(f_label[j+2]>ft.get(i)-50 && f_label[j+2]<ft.get(i)+50)
              cdn_label = true;
        }
      }
      else{
        // print frequencies >1kHz and <10kHz
        if(ft.get(i)<10000){
          if (ft.get(i-1)%1000.>900 && ft.get(i)%1000.<50){
            cdn_draw = true;
            for (int j = 0; j<3; j++)
              if(f_label[j+5]>ft.get(i)-500 && f_label[j+5]<ft.get(i)+500)
              cdn_label = true;
          }
        }
        else{
          // print frequencies >10kHz and <20kHz
          if (ft.get(i-1)%10000.>9000 && ft.get(i)%10000.<500){
            cdn_draw = true;
            if(f_label[8]>ft.get(i)-5000 && f_label[8]<ft.get(i)+5000)
              cdn_label = true;
          }
        }     
      }
    }
    if (cdn_draw){
      // print vertical lines
      //line(offset2+(i),offset2+1,offset2+(i),height-(offset2)-1);  // draw vertical line
      for (int y = -heightOver2+offset2+1; y < heightOver2-offset2-1; y++) {
        grid.fill(200); // print in black
        // Line A
        grid.vertex(i-widthOver2+offset2+1,y, 0);
        grid.vertex(i+dd-widthOver2+offset2+1, y , 0);
        grid.vertex(i+dd-widthOver2+offset2+1, y + dd, 0);
        grid.vertex(i-widthOver2+offset2+1, y + dd, 0);
      }
      // print labels
      if (cdn_label){
        double label = ft.get(i);
        double new_label = ft.get(i);
        if(ft.get(i)%10>1){
          new_label = ft.get(i)-ft.get(i)%10;
          label = new_label;
          if(ft.get(i)>1000 && ft.get(i)%1000>10){
            new_label = ft.get(i)-ft.get(i)%1000;
            label = new_label;
          }
        }
        //text(round((float)label), offset2+(i),height-(1.65*offset));
      }
    }
    nf = nf + log_step;
    cdn_draw = false;
    cdn_label = false;
  }
  
  // Draw a 4096 - Characteristic response - point to point
  int specSize = fftSize/2;
  float f_step = (fs/2.)/specSize;
  float Hw[][] = new float[specSize][2];
  // read data from a text file with frequency bin and magnitude in two columns
  String[] lines = loadStrings("8192-samples_spectrum_pinknoise.txt");
  println(lines.length +" frequency bins on the H(w) read from text file");
  Hw[0][0] = -20;
  for (int i = 0; i<specSize-1; i++){
    //Hw[i+1][0] = -20;            //fill Hw array with -3dB (testing flat Hw)
    // fill Hw array with a recorded IR from my room
    Hw[i+1][0] = (-1*float(split(lines[i+1],"-")[1]));
    //println(Hw[i+1][0]);
  }
  
  // First compute clustering from H(w) to log frequency reoslution on the display
  // as we did for linear resolution
  
  // Clustering of frequency function to draw
  
  // IMPORTANT - THIS CLUSTERING PROCESSING CAN BE IMPROVED
  // right now it loses a lot of magnitude values on low frequencies because the loop design
  // dont let to recover old data and it should be revised. Besides we need to give a 
  // frequency value to each pixel on a logarithmic resolution because the draw will improve
  nf = b1;
  float freq_step_ct = fmin;
  float dfreq_step_ct = fmin;
  float f_log_step = (float) Math.pow(2,log_step);
  int diff_fs = specSize/x_range;
  float mappedHw [][] = new float[x_range][2];
  // give a pixel label to each frequency bin
  for (int j = 0; j<x_range; j++){
    int ct_bin = 0;
    float sum_mag = 0;
    for(int k = 0; k <= specSize;k++){
      float val = f_step*k;
      if(val>ft.get(j)-(f_log_step/2) && val<ft.get(j)+(f_log_step/2)){
        Hw[k][1] = j;              // give label to each frequency bin
        // Convert to lineal to make magnitude addition 
        sum_mag = sum_mag + dB2Lineal(Hw[k][0]);
        ct_bin++;
      } else if (val>ft.get(j)+(f_log_step/2))
          continue;
    }
    // Convert to log domain (db), just after averaging
    mappedHw[j][0] = lineal2DB(sum_mag/ct_bin);
    mappedHw[j][1] = freq_step_ct;
    // update freq index for frequency display range
    nf = nf + log_step;
    dfreq_step_ct = freq_step_ct;
    freq_step_ct = (float) Math.pow(2,nf); 
    f_log_step = freq_step_ct - dfreq_step_ct; 
  }
  // Clean NaN values
  float bufferMagValues [][]= new float[x_range][3];
  int ct = 0;
  for (int j = 0; j<x_range; j++){
    if(!Float.isNaN(mappedHw[j][0])){
      bufferMagValues[ct][0] = mappedHw[j][0];
      bufferMagValues[ct][1] = mappedHw[j][1];
      bufferMagValues[ct][2] = j;
      //System.out.format("%.4fdB for %.4fHz for pixel %.1f in array position %d\n",bufferMagValues[ct][0],bufferMagValues[ct][1],bufferMagValues[ct][2], ct);
      ct++;
    }
  }
  
  // Draw on logarithmic MODE
  
  // Already we have a f array with the frequency values related to a 
  // logarithmic frequency resolution. So, in this case we can try to draw the pixel
  // to the closer frequency bin related from the H(w) readed from txt.
  
  // Drawing with linear interpolation a 4096 - Characteristic response (mappedHw)
  bufferMagValues[0][1] = map(bufferMagValues[0][0], up_bond, down_bond,-heightOver2+offset2+1, heightOver2-(offset2+1));
  int ctt = 1;
  for(int i=1;i<x_range-1;i++){
    if(i == int(bufferMagValues[ctt][2])){
      // map decibel value to pixel on the display
      bufferMagValues[ctt][1] = map(bufferMagValues[ctt][0], up_bond, down_bond,-heightOver2+offset2+1, heightOver2-(offset2+1));
      // draw by points
      strokeWeight(3);
      stroke(200,50,50);
      // Avoiding function values out of display range - limited by magnitude boundaries
      float a_y = bufferMagValues[ctt-1][1];
      float b_y = bufferMagValues[ctt][1];
      // applying boundaries
      if (bufferMagValues[ctt-1][1]>heightOver2-offset2) // if odd value is down out range
        a_y = heightOver2-(offset2+1);
      else if (bufferMagValues[ctt-1][1]<-heightOver2+offset2)
        a_y = -heightOver2+offset2+1;
      else if (bufferMagValues[ctt][1]>heightOver2-offset2)
        b_y = heightOver2-(offset2+1);
      else if (bufferMagValues[ctt][1]<-heightOver2+offset2)
        b_y = -heightOver2+offset2+1;
      // Avoiding values out of display range - in terms of magnitude
      if((bufferMagValues[ctt-1][1]>heightOver2-offset2 && bufferMagValues[ctt][1]>heightOver2-offset2) ||(bufferMagValues[ctt-1][1]<-heightOver2+offset2+1 && bufferMagValues[ctt][1]<-heightOver2+offset2+1))
        {
          ctt++;
          continue;
        }
       // Lineal interpolation
      //line(offset2+2+bufferMagValues[ctt-1][2],a_y, offset2+1+bufferMagValues[ctt][2],a_y);
      //line(offset2+1+i,a_y, offset2+1+i+1,b_y);
      grid.fill(200,100,100); // print in red
      // Line A
      grid.vertex(i-widthOver2+offset2+1,a_y, 0);
      grid.vertex(i-widthOver2+offset2+1+dd,a_y+dd, 0);
      grid.vertex(i-widthOver2+offset2+1+1, b_y , 0);
      grid.vertex(i-widthOver2+offset2+1+1+dd, b_y+dd , 0);
      //grid.vertex(i+dd-widthOver2+offset2+1, y + dd, 0);
      //grid.vertex(i-widthOver2+offset2+1, y + dd, 0);
      // TOTHINK - use other interpolation or apply a smoothing function.
      ctt ++;
    }
  }
  strokeWeight(1);
  grid.endShape();
  
  // 2- Draw frame
  frame = createShape();
  frame.beginShape(QUADS);        // If no mode is specified, the shape can be any irregular polygon
  frame.noStroke();  
  frame.fill(220);
  //side left QUAD
  frame.vertex(0, 0, 0);
  frame.vertex(offset2, 0, 0);
  frame.vertex(offset2, height, 0);
  frame.vertex(0, height, 0);
  //side right QUAD
  frame.vertex(width-offset2, 0, 0);
  frame.vertex(width, 0, 0);
  frame.vertex(width, height, 0);
  frame.vertex(width-offset2, height, 0);
  // upper bar QUAD
  frame.vertex(0, 0, 0);
  frame.vertex(width, 0, 0);
  frame.vertex(width, offset2, 0);
  frame.vertex(0, offset2, 0);
  // down bar QUAD
  frame.vertex(0, height-offset2, 0);
  frame.vertex(width, height-offset2, 0);
  frame.vertex(width, height, 0);
  frame.vertex(0, height, 0);
  frame.endShape();
  
  // NEXT TODO - 
  /* 1 - Draw on logarithmic MODE - DONE - THINK on increase low frequency resolution
     2 - Use grid class.
     2 - Apply zoom with key or buttons.
     3 - Encapsulate Hw plot in a class.
     */
}

void draw() {
  // Draw display boundaries with a white rect with black strokes
  fill(255);
  stroke(0);
  rect(offset2, offset2, displayWidth-(2*offset2), displayHeight-(2*offset2));
  pushMatrix();
  translate(width/2, height/2);
  //zoom_x = map(mouseX, 0, width, 1, 4.5);
  //zoom_y = map(mouseY, 0, height, 1, 4.5);
  //println(zoom);
  scale(zoom_x,zoom_y);
  translate(tras_x, tras_y);
  shape(grid);
  popMatrix();
  shape(frame);
  
  // Draw db range at left vertical border - (y-axis)
  stroke(0);
  textSize(18);
  fill(0);
  text(str(down_bond), offset+5+30, down_vt_label);  // down boundary
  text(str(up_bond), offset+15+30, up_vt_label);  // up boundary
  // Draw y-axis labels
  for (int i = 1; i < nlines; i++) {
    String label = str(up_bond - (line_grid_space * i));
    int x_posLabel = offset + 5 + 30;
    // Correction of label location
    if (label.length()<3)
      x_posLabel = offset+15+30;
    if (label.length()<2)
      x_posLabel = offset+25+30;       
    // print labels
    fill(0);
    text(label, x_posLabel, up_vt_label+(i*(step_6dBs+1)));
  }
  // Draw y-axis label
  ylabel(offset, heightOver2, "Magnitude [dB]");
  xlabel(widthOver2, height-offset, "Frequency [Hz]");
  // Frequency labels
  // Draw the first and last frequency label
  double textf = ft.get(0);    // auto-boxing converting Double to double to apply round function
  text(round((float)textf), offset2,height-(1.65*offset));
  text(fmax,offset2+x_range,height-(1.65*offset));
  // Draw Title
  textSize(26);
  text("Characteristic Response", widthOver2, offset);
  // Draw buttons
  fill(255);
  rect(0,0,150,100);
  rect(width-150,0,width,100);
  fill(0);
  text("Zoom Out", 50+25, 60);
  text("Zoom In", width-150 + 50+25, 60);
  // User Feedback
  textSize(12);
  text("traslate(" + str(tras_x) + ", " + str(tras_y)+"); zoom("+str(zoom_x)+", "+str(zoom_y)+")", offset2, height-offset); 
}

void mousePressed(){
  if((mouseX>0 && mouseX<150) && (mouseY>0 && mouseY<100))
    if (zoom_x>1.){
      // applied on x and y axes
      zoom_x = zoom_x-.1;
      zoom_y = zoom_y-.1;
    }
    // when display is showing all the frequency range zoom In is only applied on y axis
    else
      if(zoom_y >.5)
        zoom_y = zoom_y-.02;
    
  if((mouseX>width-150 && mouseX<width) && (mouseY>0 && mouseY<100))
    if (zoom_y>=1.){
      if(zoom_x<4.){
        zoom_x = zoom_x+.1;
        zoom_y = zoom_y+.1;  
      }
    }else
        zoom_y = zoom_y+.02;
   // Apply translation with dragging
   if((mouseX>offset2 && mouseX<width-offset2) && (mouseY>offset2 && mouseY<height-offset2))
   {
     println("Pressed Inside magnitude display, x: " + mouseX + ", y: "+ mouseY);
     mouseClickX = mouseX;
     mouseClickY = mouseY;
   }
  //println("zoom_y: " + zoom_y);
}
void mouseReleased(){
  if(zoom_x>1){
    if((mouseX>offset2 && mouseX<width-offset2) && (mouseY>offset2 && mouseY<height-offset2))
     {
       //println("Released inside magnitude display, x: " + mouseX + ", y: "+ mouseY);
       if (mouseClickX!=-100){
         tras_x = tras_x + int((mouseX- mouseClickX)* 1/zoom_x);
         tras_y = tras_y + int((mouseY- mouseClickY)*1/zoom_y);
         if (Math.abs(tras_x)>widthOver2/2)
           tras_x = widthOver2/2;
         if (Math.abs(tras_y)>widthOver2/2)
           tras_y = heightOver2/2;
       }
     }
     else
       println("Released outside magnitude display, x: " + mouseX + ", y: "+ mouseY);
  }
   println("tras_x: "+tras_x +", tras_y: " + tras_y);
}
void keyPressed(){
  if (key=='C' || key == 'c'){
    zoom_x = 1.;
    zoom_y = 1.;
    tras_x = 0;
    tras_y = 0;
  } else if(keyCode == UP){
    zoom_x = zoom_x+0.1;
    zoom_y = zoom_y+0.1;
  } else if(keyCode == DOWN){
    zoom_x = zoom_x-0.1;
    zoom_y = zoom_y-0.1;
  }else if(keyCode == LEFT){
    tras_x = tras_x-3;
    //tras_y = tras_y+3;
  } else if(keyCode == RIGHT){
    tras_x = tras_x+3;
    //tras_y = tras_y-3;
  }
  
}
float dB2Lineal(float dB){
  float lin = (float)Math.pow(10.,dB/20.);
  return lin;
}

float lineal2DB(float smp){
  float dB = (float)(20.*(Math.log(smp)/Math.log(10.)));
  return dB;
}

void drawHorizontalDashedLine(int lx, int y, int gx, int color_line) {
  for (int x = lx; x < gx; x += 3) {
    stroke(-(x+y>>1 & 1));
    //println(-(x+y>>1 & 1));
    if (-(x+y>>1 & 1)==0)
      stroke(color_line);
    line(x, y, x+3, y);
  }
}

void ylabel(int x, int y, String label){
  textAlign(CENTER,BOTTOM);
  textSize(22);
  pushMatrix();
  translate(x,y);
  rotate(-HALF_PI);
  text(label,0,0);
  popMatrix();
}

void xlabel(int x, int y, String label){
  textAlign(CENTER,BOTTOM);
  textSize(22);
  pushMatrix();
  translate(x,y);
  text(label,0,0);
  popMatrix();
}

void drawRedPointMark(int p_x, int p_y) {
  // Draw mark
  strokeWeight(10);
  fill(255, 0, 0);
  stroke(255, 0, 0);
  point(p_x, p_y);
}

double distBetweenPoints(Point A, Point B) {
  double dist = Math.sqrt(Math.pow(A.x-B.x, 2)+Math.pow(A.y-B.y, 2));
  return dist;
}

Point diffBetweenPoints(Point A, Point B) {
  Point diff = new Point();
  diff.set_pos(B.x-A.x, B.y-A.y);
  return diff;
}

class Point {
  int x;
  int y;

  Point() {
    this.x = 0;
    this.y = 0;
  }
  void set_pos(int x, int y) {
    this.x = x;
    this.y = y;
  }
}