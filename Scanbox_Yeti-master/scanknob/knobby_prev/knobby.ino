
// Knobby - dlr (1/28/16)

#include <Encoder.h>
#include <stdio.h>
#include <stdarg.h>

#include <Adafruit_GFX.h> // Core graphics library
#include <SPI.h> // this is needed for display
#include <Adafruit_ILI9341.h>
#include <Wire.h> // this is needed for FT6206
#include <Adafruit_FT6206.h>
#include <SD.h>

// #include <Fonts/FreeSans12pt7b.h>
#define SD_CS 4

// The FT6206 uses hardware I2C (SCL/SDA)
Adafruit_FT6206 ctp = Adafruit_FT6206();

// The display also uses hardware SPI, plus #9 & #10
#define TFT_CS 10
#define TFT_DC 9
Adafruit_ILI9341 tft = Adafruit_ILI9341(TFT_CS, TFT_DC);

#define LEN 32
char buf[LEN];  // formatting buffer

#define X 2     // motor axes
#define Y 1
#define Z 0
#define A 3

//encoder pins

// Jen's wiring
Encoder x(32, 30);
Encoder y(36, 34);
Encoder z(40, 38);
Encoder a(44, 42);

// Dario's wiring

//Encoder x(30, 32);
//Encoder y(34, 36);
//Encoder z(38, 40);
//Encoder a(42, 44);

#define DIN 28
#define DOUT 46

unsigned char cmd[5];

const float pi = 3.14159265358;
char  motor_char[4] = {'Z', 'Y', 'X', 'A'};
float motor_gain[4] = {2000.0 / 400.0 / 32.0 / 2.0, (0.02 * 25400.0) / 400.0 / 64.0, (0.02 * 25400.0) / 400.0 / 64.0, 0.0225 / 64.0}; // pos to um and deg

long  p[4] = {0, 0, 0, 0};   // old position
long  n[4] = {0, 0, 0, 0};   // new position
long  dpos[4] = {0, 0, 0, 0}; // delta position w/speed

long  mpos[3][4];           // memory
long  mflag[3] = {0, 0, 0}; // 1 if there is something stored...

int vel = 0;  // coarse, fine, superfine
float mstep[3][4] = {{10, 3.9370 * 10, 3.9370 * 10 , 10}, {5, 3.9370 * 20, 3.9370 * 20, 5}, {1, 3.9370, 3.9370, 1}}; // step per unit count
int mode = 0; // normal, rotate
int flag = 0; // debounce screen touch
long t0;      // time
int sflag = 0;// storage button pressed
int rflag = 0;// recall button pressed
int zflag = 0;// zero button pressed
int uflag = 0;// update flag used during recall
int lock = 0; // are screen and knobs locked?
const int order[4] = {2, 1, 0, 3};

long xs, ys;  // screen
TS_Point pt;

int IRQcount = 0;
// formatting function

void format(char *fmt, ...) {

  va_list args;
  va_start(args, fmt);
  vsnprintf((char *) buf, LEN, fmt, args);
  va_end(args);
}

void format_dlr(char c, float x, int m) {
  int n, j, k;
  buf[m + 1] = 0;
  n = int(100 * abs(x));
  j = m;
  while (j >= 5) {
    k = n - 10 * (n / 10);
    buf[j] = '0' + k;
    j--;
    if (j == m - 2) {
      buf[j] = '.';
      j--;
    }
    n = n / 10;
  }
  buf[0] = c; buf[1] = buf[3] = ' '; buf[2] = '=';
  if (x >= 0) buf[4] = '+'; else buf[4] = '-';
}

// screen update functions

void update_axis(int n, long val) {
  //tft.fillRect(65, 65 + order[n] * 30, 120, 20, ILI9341_BLACK);
  tft.setCursor(30, 70 + order[n] * 30);
  tft.setTextColor(ILI9341_YELLOW, ILI9341_BLACK);
  //format("%c = %04.2f", motor_char[n], (float)val * motor_gain[n]);
  if (n != 3) format_dlr(motor_char[n], (float)val * motor_gain[n], 12);
  else format_dlr(motor_char[n], (float)val * motor_gain[n], 9);
  tft.print(buf);
}

void updatelock(int lock) {

  tft.fillRect(20, 15, 120, 35, ILI9341_BLACK);
  tft.setCursor(30, 25);
  switch (lock) {
    case 0:
      tft.setTextColor(ILI9341_GREEN);
      tft.print("Unlocked");
      break;
    case 1:
      tft.setTextColor(ILI9341_RED);
      tft.print("Locked!!");
      break;
  }
}



void updatev(int val) {

  tft.fillRect(210, 15, 100, 40, ILI9341_BLACK);
  tft.setTextColor(ILI9341_CYAN);
  tft.setCursor(220, 25);
  switch (val) {
    case 0:
      tft.print("Coarse");
      break;
    case 1:
      tft.print("Fine ");
      break;
    case 2:
      tft.print("S-Fine");
      break;
  }
}

void updatem(int val) {

  tft.fillRect(210, 60 , 100, 40, ILI9341_BLACK);
  tft.setTextColor(ILI9341_CYAN);
  tft.setCursor(220, 70);
  switch (val) {
    case 0:
      tft.print("Normal");
      break;
    case 1:
      tft.print("Rotate");
      break;
  }
}

void updatezero(int val) {

  tft.setCursor(220, 115);

  if (val) {
    tft.setTextColor(ILI9341_MAGENTA);
    tft.print("Zero");
    tft.setCursor(30, 205);
    tft.print("All     XYZ");
  } else {
    tft.setTextColor(ILI9341_CYAN);
    tft.print("Zero");
  }

}

void updatestore(int val) {

  tft.setCursor(220, 160);

  if (val) {
    tft.setTextColor(ILI9341_MAGENTA);
    tft.print("Store");
    tft.setCursor(30, 205);
    if (mflag[0]) tft.setTextColor(ILI9341_WHITE); else tft.setTextColor(ILI9341_MAGENTA);
    tft.print("A   ");
    if (mflag[1]) tft.setTextColor(ILI9341_WHITE); else tft.setTextColor(ILI9341_MAGENTA);
    tft.print("B   ");
    if (mflag[2]) tft.setTextColor(ILI9341_WHITE); else tft.setTextColor(ILI9341_MAGENTA);
    tft.print("C");
  } else {
    tft.setTextColor(ILI9341_CYAN);
    tft.print("Store");
  }
}

void updaterecall(int val) {

  tft.setCursor(220, 205);

  if (val) {
    tft.setTextColor(ILI9341_MAGENTA);
    tft.print("Recall");
    tft.setCursor(30, 205);
    if (mflag[0]) tft.setTextColor(ILI9341_WHITE); else tft.setTextColor(ILI9341_MAGENTA);
    tft.print("A   ");
    if (mflag[1]) tft.setTextColor(ILI9341_WHITE); else tft.setTextColor(ILI9341_MAGENTA);
    tft.print("B   ");
    if (mflag[2]) tft.setTextColor(ILI9341_WHITE); else tft.setTextColor(ILI9341_MAGENTA);
    tft.print("C");
  } else {
    tft.setTextColor(ILI9341_CYAN);
    tft.print("Recall");
  }
}

// The setup!

void setup() {

  // begin serial

  Serial.begin(57600);
  delay(1000);

  // start the screen and welcome message
  tft.begin();
  ctp.begin(40);
  tft.fillScreen(ILI9341_BLACK);
  SD.begin(SD_CS);
  bmpDraw("welcome.bmp", 0, 0); // Welcome screen
  int t0 = millis();
  while (millis() - t0 < 2500); // display for 3sec

  tft.setRotation(1);
  tft.fillScreen(ILI9341_BLACK);
  //tft.setFont(&FreeSans12pt7b);
  tft.setTextSize(2);

  updatelock(lock);
  updatev(vel);
  updatem(mode);
  updatezero(0);
  updatestore(0);
  updaterecall(0);

  // update readings
  x.write(0); y.write(0); z.write(0); a.write(0);
  for (int i = 0; i < 4 ; i++) update_axis(i, 0);

  // SMA connectors

  //  pinMode(DIN, INPUT);
  //  pinMode(DOUT, OUTPUT); digitalWrite(DOUT, LOW);
  //  attachInterrupt(DIN, IRQcounter, RISING);
  //  noInterrupts();
  //  IRQcount = 0;
}

//void IRQcounter() {
//  IRQcount++;
//}


void loop() {

  int k, i, j;
  long nval, delta;
  float th;
  int dirty[4];
  unsigned char cmd[4];


  if (Serial.available() >= 9) {      // external MVP command
    Serial.readBytes(buf, 4);              // consume...
    int motor = buf[3];

    k = 1;
    delta = 0;
    for (i = 0; i < 4; i++)
      for (j = 0; j < 8; j++) {
        bitWrite(delta, k, bitRead(buf[7 - i], j));
        k = k + 1;
      }

    switch (buf[0]) {
      case 0:
        z.write(z.read() + delta);
        break;
      case 1:
        y.write(y.read() + delta);
        break;
      case 2:
        x.write(x.read() + delta);
        break;
      case 3:
        a.write(a.read() + delta);
      default:
        break;
    }
  }

  if (lock == 0) {

    if (uflag) {                  // force a full update....  for example during recall of a memory or zeroing...

      for (int i = 0; i < 4; i++) {  // for each axis
        p[i] = n[i];
        cmd[0] = i;                // reporting position for motor i
        Serial.write(cmd[0]);      // send motor # as command
        for (int j = 0; j <= 3; j++) {
          Serial.write( (dpos[i] >> (8 * j)) & 0x0ff );
        }
        update_axis(i, dpos[i]);
      }
      uflag = 0;

    } else {                        // take care of knobs...

      n[Z] = z.read(); n[Y] = y.read(); n[X] = x.read(); n[A] = a.read();   //read new position

      if (mode == 0) {              // normal mode

        for (int i = 0; i < 4; i++) {  // for each axis

          if (n[i] != p[i]) {        // if it changed from prior position
            dpos[i] += long(float(n[i] - p[i]) * mstep[vel][i]); // integrate to obtain desired position
            p[i] = n[i];
            cmd[0] = i;                // reporting the new position for motor i
            Serial.write(cmd[0]);      // send motor # as command
            for (int j = 0; j <= 3; j++) {
              Serial.write( (dpos[i] >> (8 * j)) & 0x0ff );
            }
            update_axis(i, dpos[i]);   // update the screen reading
          }
        }
      } else {                      // rotated mode

        for (int i = 0; i < 4; i++) dirty[i] = 0;

        for (int i = 0; i < 4; i++) {  // for each axis

          if (n[i] != p[i]) {        // if it changed
            switch (i) {
              case 1:
              case 3:            // nothing different in y and theta
                dpos[i] += long(float(n[i] - p[i]) * mstep[vel][i]);
                p[i] = n[i];
                dirty[i] = 1;
                break;
              case 0: // z
                dirty[0] = dirty[2] = 1;  //both x and z need to be moved
                th = -(float) dpos[3] * motor_gain[3] * pi / 180.0;
                dpos[0] += long(float(n[i] - p[i]) * mstep[vel][0] * cos(th));
                dpos[2] += long(float(n[i] - p[i]) * mstep[vel][2] * sin(th));
                p[0] = n[0];
                break;
              case 2: // x
                dirty[0] = dirty[2] = 1;
                th = -(float) dpos[3] * motor_gain[3] * pi / 180.0;
                dpos[0] += -long(float(n[i] - p[i]) * mstep[vel][0] * sin(th));
                dpos[2] +=  long(float(n[i] - p[i]) * mstep[vel][2] * cos(th));
                p[2] = n[2];
                break;
            }
          }
        }

        for (int i = 0; i < 4; i++) {
          if (dirty[i]) {
            cmd[0] = i;                // reporting position for motor i
            Serial.write(cmd[0]);      // send motor # as command
            for (int j = 0; j <= 3; j++) {
              Serial.write( (dpos[i] >> (8 * j)) & 0x0ff );
            }
            update_axis(i, dpos[i]);
          }
        }
      }
    }

  }
  // now check the screen....

  switch (flag) {
    case 0:       // waiting for screen touch
      if (ctp.touched()) flag = 1;
      t0 = millis();
      pt = ctp.getPoint();
      xs = pt.x;        // get screen coordinates
      ys = pt.y;
      break;

    case 1:       // the screen was touched....  wait 150ms
      if (ctp.touched()) {
        if (millis() - t0 > 30)
          flag = 2;
      }
      else flag = 0;
      break;

    case 2:        // process....

//      Serial.println("---");
//      Serial.println(xs);
//      Serial.println(ys);

      if (xs < 60 && ys > 180) {  // was 40 and 200
        lock = 1 - lock;
        updatelock(lock);
        if (lock == 0) {            // we are unlocking!
          p[Z] = n[Z] = z.read();
          p[Y] = n[Y] = y.read();
          p[X] = n[X] = x.read();
          p[A] = n[A] = a.read();   // ignore any knob movements during lock!
        }
      }

      if (lock == 0) {

        if (rflag == 0 && sflag == 0 && zflag == 0) { // if NOT in store / recall / zero mode

          if (ys < 120) { // clicking somwhere on right menu

            if ( abs(xs - 30) < 22 ) {  // switch between coarse/fine/superfine

              switch (vel) {
                case 0:
                  vel = 1;
                  break;
                case 1:
                  vel = 2;
                  break;
                case 2:
                  vel = 0;
                  break;
                default:
                  break;
              }
              updatev(vel);
            }

            if ( abs(xs - 75) < 22) {   // switch between normal and rotate

              switch (mode) {
                case 0:
                  mode = 1;             // normal and rotate modes
                  break;
                case 1:
                  mode = 0;
                  break;
                default:
                  break;
              }

              updatem(mode);

            }

            if (abs(xs - 120) < 22) {   // zero
              zflag = 1;
              updatezero(zflag);
            }

            if ( abs(xs - 165) < 22) {  // store mode
              sflag = 1;
              updatestore(sflag);
            }

            if ( abs(xs - 210) < 22) {  // recall mode
              rflag = 1;
              updaterecall(rflag);
            }

          }
          
        } else { // store or recall or zero are on...

          if (xs < 180 || ys < 120) {                   // clicked outside the bottomn selection menu... cancel 
            sflag = zflag = rflag = 0;
            tft.fillRect(20, 200 , 160, 20, ILI9341_BLACK);
            updatestore(0);
            updatezero(0);
            updaterecall(0);
            flag = 3;
            return;
            
          }  else  {   // store/recall selection

            int sel = -1;
//            if (abs(ys - 280) < 30) sel = 0;
//            if (abs(ys - 220) < 30) sel = 1;
//            if (abs(ys - 160) < 30) sel = 2;

            if (abs(ys - 270) < 30) sel = 0;
            if (abs(ys - 227) < 30) sel = 1;
            if (abs(ys - 181) < 30) sel = 2;

            // Serial.println(sel);

            tft.fillRect(20, 200 , 160, 20, ILI9341_BLACK);

            if (sflag) {
              mpos[sel][X] = dpos[X];
              mpos[sel][Y] = dpos[Y];
              mpos[sel][Z] = dpos[Z];
              mpos[sel][A] = dpos[A];
              mflag[sel] = 1;
              sflag = 0;
              updatestore(sflag);
            }

            if (rflag) {
              if (mflag[sel]) {
                dpos[X] = mpos[sel][X];
                dpos[Y] = mpos[sel][Y];
                dpos[Z] = mpos[sel][Z];
                dpos[A] = mpos[sel][A];
                uflag = 1;
              }
              rflag = 0;
              updaterecall(rflag);
            }

            if (zflag) { // zero

              switch (sel) {
                case 0:   //vertical align and then zero....
                  x.write(0); y.write(0); z.write(0); a.write(0);
                  mflag[0] = mflag[1] = mflag[2] = 0;
                  n[Z] = n[Y] = n[X] = n[A] = 0;
                  p[Z] = p[Y] = p[X] = p[A] = 0;
                  dpos[Z] = dpos[Y] = dpos[X] = dpos[A] = 0;
                  for ( i = 0; i < 4 ; i++) update_axis(i, 0);
                  cmd[0] = 11;
                  Serial.write(cmd, 5);     // send zero command...

                  break;
                case 1:
                  break;
                case 2:   // zero XYZ only...
                  x.write(0); y.write(0); z.write(0);
                  mflag[0] = mflag[1] = mflag[2] = 0;
                  n[Z] = n[Y] = n[X] =  0;
                  p[Z] = p[Y] = p[X] =  0;
                  dpos[Z] = dpos[Y] = dpos[X] =  0;
                  for ( i = 0; i < 3 ; i++) update_axis(i, 0);
                  cmd[0] = 10;
                  Serial.write(cmd, 5);     // send zero command...
                  break;
              }

              zflag = 0;
              updatezero(zflag);
            }
          }
        }
      }

      flag = 3;
      break;

    case 3:                   // wait for screen release....
      if (!ctp.touched())
        flag = 0;
      break;
  }
}


// This function opens a Windows Bitmap (BMP) file and
// displays it at the given coordinates. It's sped up
// by reading many pixels worth of data at a time
// (rather than pixel by pixel). Increasing the buffer
// size takes more of the Arduino's precious RAM but
// makes loading a little faster. 20 pixels seems a
// good balance.

#define BUFFPIXEL 20

void bmpDraw(char *filename, uint8_t x, uint16_t y) {

  File bmpFile;
  int bmpWidth, bmpHeight; // W+H in pixels
  uint8_t bmpDepth; // Bit depth (currently must be 24)
  uint32_t bmpImageoffset; // Start of image data in file
  uint32_t rowSize; // Not always = bmpWidth; may have padding
  uint8_t sdbuffer[3 * BUFFPIXEL]; // pixel buffer (R+G+B per pixel)
  uint8_t buffidx = sizeof(sdbuffer); // Current position in sdbuffer
  boolean goodBmp = false; // Set to true on valid header parse
  boolean flip = true; // BMP is stored bottom-to-top
  int w, h, row, col;
  uint8_t r, g, b;
  uint32_t pos = 0, startTime = millis();

  if ((x >= tft.width()) || (y >= tft.height())) return;

  //  Serial.println();
  //  Serial.print(F("Loading image '"));
  //  Serial.print(filename);
  //  Serial.println('\'');

  // Open requested file on SD card
  if ((bmpFile = SD.open(filename)) == NULL) {
    //Serial.print(F("File not found"));
    return;
  }

  // Parse BMP header
  if (read16(bmpFile) == 0x4D42) { // BMP signature
    //Serial.print(F("File size: ")); Serial.println(read32(bmpFile));
    read32(bmpFile);
    (void)read32(bmpFile); // Read & ignore creator bytes
    bmpImageoffset = read32(bmpFile); // Start of image data
    //Serial.print(F("Image Offset: ")); Serial.println(bmpImageoffset, DEC);
    // Read DIB header
    //Serial.print(F("Header size: ")); Serial.println(read32(bmpFile));
    read32(bmpFile);
    bmpWidth = read32(bmpFile);
    bmpHeight = read32(bmpFile);
    if (read16(bmpFile) == 1) { // # planes -- must be '1'
      bmpDepth = read16(bmpFile); // bits per pixel
      //Serial.print(F("Bit Depth: ")); Serial.println(bmpDepth);
      if ((bmpDepth == 24) && (read32(bmpFile) == 0)) { // 0 = uncompressed

        goodBmp = true; // Supported BMP format -- proceed!
        //Serial.print(F("Image size: "));
        //Serial.print(bmpWidth);
        //Serial.print('x');
        //Serial.println(bmpHeight);

        // BMP rows are padded (if needed) to 4-byte boundary
        rowSize = (bmpWidth * 3 + 3) & ~3;

        // If bmpHeight is negative, image is in top-down order.
        // This is not canon but has been observed in the wild.
        if (bmpHeight < 0) {
          bmpHeight = -bmpHeight;
          flip = false;
        }

        // Crop area to be loaded
        w = bmpWidth;
        h = bmpHeight;
        if ((x + w - 1) >= tft.width()) w = tft.width() - x;
        if ((y + h - 1) >= tft.height()) h = tft.height() - y;

        // Set TFT address window to clipped image bounds
        tft.setAddrWindow(x, y, x + w - 1, y + h - 1);

        for (row = 0; row < h; row++) { // For each scanline...

          // Seek to start of scan line. It might seem labor-
          // intensive to be doing this on every line, but this
          // method covers a lot of gritty details like cropping
          // and scanline padding. Also, the seek only takes
          // place if the file position actually needs to change
          // (avoids a lot of cluster math in SD library).
          if (flip) // Bitmap is stored bottom-to-top order (normal BMP)
            pos = bmpImageoffset + (bmpHeight - 1 - row) * rowSize;
          else // Bitmap is stored top-to-bottom
            pos = bmpImageoffset + row * rowSize;
          if (bmpFile.position() != pos) { // Need seek?
            bmpFile.seek(pos);
            buffidx = sizeof(sdbuffer); // Force buffer reload
          }

          for (col = 0; col < w; col++) { // For each pixel...
            // Time to read more pixel data?
            if (buffidx >= sizeof(sdbuffer)) { // Indeed
              bmpFile.read(sdbuffer, sizeof(sdbuffer));
              buffidx = 0; // Set index to beginning
            }

            // Convert pixel from BMP to TFT format, push to display
            b = sdbuffer[buffidx++];
            g = sdbuffer[buffidx++];
            r = sdbuffer[buffidx++];
            tft.pushColor(tft.color565(r, g, b));
          } // end pixel
        } // end scanline
        //Serial.print(F("Loaded in "));
        //Serial.print(millis() - startTime);
        //Serial.println(" ms");
      } // end goodBmp
    }
  }

  bmpFile.close();
  // if (!goodBmp) Serial.println(F("BMP format not recognized."));
}

// These read 16- and 32-bit types from the SD card file.
// BMP data is stored little-endian, Arduino is little-endian too.
// May need to reverse subscript order if porting elsewhere.

uint16_t read16(File & f) {
  uint16_t result;
  ((uint8_t *)&result)[0] = f.read(); // LSB
  ((uint8_t *)&result)[1] = f.read(); // MSB
  return result;
}

uint32_t read32(File & f) {
  uint32_t result;
  ((uint8_t *)&result)[0] = f.read(); // LSB
  ((uint8_t *)&result)[1] = f.read();
  ((uint8_t *)&result)[2] = f.read();
  ((uint8_t *)&result)[3] = f.read(); // MSB
  return result;
}
