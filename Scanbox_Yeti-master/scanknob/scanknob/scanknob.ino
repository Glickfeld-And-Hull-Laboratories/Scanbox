
#include <Encoder.h>
#include <stdio.h>
#include <stdarg.h>

#include <Adafruit_GFX.h> // Core graphics library
#include <SPI.h> // this is needed for display
#include <Adafruit_ILI9341.h>
#include <Wire.h> // this is needed for FT6206
#include <Adafruit_FT6206.h>
#include <SD.h>
#define SD_CS 4

// The FT6206 uses hardware I2C (SCL/SDA)
Adafruit_FT6206 ctp = Adafruit_FT6206();

// The display also uses hardware SPI, plus #9 & #10
#define TFT_CS 10
#define TFT_DC 9
Adafruit_ILI9341 tft = Adafruit_ILI9341(TFT_CS, TFT_DC);

#define LEN 20
char buf[LEN];  // formatting buffer

#define X 2     // motor axes
#define Y 1
#define Z 0
#define A 3

//encoder pins

Encoder x(26, 24); // means pins 28 & 29 must be LOW
Encoder y(36, 34);
Encoder z(46, 44); // means pins 46 & 47 must be HIGH
Encoder a(27, 25);

unsigned char cmd[5];

char  motor_char[4] = {'Z', 'Y', 'X', 'A'};
float motor_gain[4] = {2000.0 / 400.0 / 32.0 / 2.0, (0.02 * 25400.0) / 400.0 / 64.0, (0.02 * 25400.0) / 400.0 / 64.0, 0.0225 / 64.0}; // pos to um and deg

long  p[4] = {0, 0, 0, 0};   // old position
long  n[4] = {0, 0, 0, 0};   // new position
long  dpos[4] = {0, 0, 0, 0}; // delta position w/speed

long  mpos[3][4];           // memory
long  mflag[3] = {0, 0, 0}; // 1 if there is something stored...

int vel = 0;  // coarse, fine, superfine
int mstep = 10; // step per unit count
int mode = 0; // normal, rotate
int flag = 0; // debounce screen touch
long t0;      // time
int sflag = 0;// storage button pressed
int rflag = 0;// recall button pressed
int zflag = 0;// zero button pressed
int uflag = 0;// update flag used during recall

// formatting function

void format(char *fmt, ...) {

  va_list args;
  va_start(args, fmt);
  vsnprintf((char *) buf, LEN, fmt, args);
  va_end(args);
}

// screen update functions

void update_axis(int n, long val) {
  tft.fillRect(65, 65 + n * 30, 120, 20, ILI9341_BLACK);
  tft.setCursor(30, 70 + n * 30);
  tft.setTextColor(ILI9341_YELLOW);
  format("%c = %+.2f", motor_char[n], (float)val * motor_gain[n]);
  tft.print(buf);
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
    tft.print("All   XYZ");

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

  // GND

  pinMode(28, OUTPUT);  digitalWrite(28, LOW);
  pinMode(29, OUTPUT);  digitalWrite(29, LOW);
  pinMode(38, OUTPUT);  digitalWrite(38, LOW);
  pinMode(48, OUTPUT);  digitalWrite(48, LOW);

  //  VCC external

  pinMode(30, INPUT);
  pinMode(31, INPUT);
  pinMode(40, INPUT);


  // begin serial

  Serial.begin(57600);

  // pause

  delay(1000);

  // start the screen and welcome message
  tft.begin();
  ctp.begin(40);
  tft.fillScreen(ILI9341_BLACK);

  SD.begin(SD_CS);
  bmpDraw("welcome.bmp", 0, 0); // Welcome screen
  int t0 = millis();
  while (millis() - t0 < 2000); // display for 3sec

  tft.setRotation(1);
  tft.fillScreen(ILI9341_BLACK);
  tft.setTextSize(2);

  updatev(vel);
  updatem(mode);
  updatezero(0);
  updatestore(0);
  updaterecall(0);

  // update readings
  x.write(0); y.write(0); z.write(0); a.write(0);
  for (int i = 0; i < 4 ; i++) update_axis(i, 0);

}


void loop() {

  int k, i;
  long nval;

  // see if we need to update position

  if (Serial.available() >= 1) { // external command
    Serial.read();               // consume...
  }

  if (uflag) {

    for (int i = 0; i < 4; i++) {  // for each axis

      if ((n[i] != p[i]) || (uflag > 0) ) {        // if it changed
        dpos[i] += (n[i] - p[i]) * mstep;
        p[i] = n[i];
        cmd[0] = i;                // reporting position for motor i
        Serial.write(cmd[0]);      // send motor # as command
        for (int j = 0; j <= 3; j++) {
          Serial.write( (dpos[i] >> (8 * j)) & 0x0ff );
        }
        update_axis(i, dpos[i]);
      }
    }

  }


  n[Z] = z.read(); n[Y] = y.read(); n[X] = x.read(); n[A] = a.read();

  for (int i = 0; i < 4; i++) {  // for each axis

    if ((n[i] != p[i]) || (uflag > 0) ) {        // if it changed
      dpos[i] += (n[i] - p[i]) * mstep;
      p[i] = n[i];
      cmd[0] = i;                // reporting position for motor i
      Serial.write(cmd[0]);      // send motor # as command
      for (int j = 0; j <= 3; j++) {
        Serial.write( (dpos[i] >> (8 * j)) & 0x0ff );
      }
      update_axis(i, dpos[i]);
    }
  }

  uflag = 0;

  if (! ctp.touched()) {   // no screen input
    return;
  }

  if (flag) {             // debounce
    if (millis() - t0 < 150) return;
  }

  t0 = millis();
  flag = 1;

  // Retrieve a point
  TS_Point pt = ctp.getPoint();

  long xs = pt.x;        // get screen coordinates
  long ys = pt.y;

  if (rflag == 0 && sflag == 0 && zflag == 0) { // if not in store / recall / zero mode

    if (ys < 120) {

      if ( abs(xs - 30) < 22 ) {  // switch between coarse/fine/superfine

        switch (vel) {
          case 0:
            vel = 1;
            mstep = 5;
            break;
          case 1:
            vel = 2;
            mstep = 1;
            break;
          case 2:
            vel = 0;
            mstep = 10;
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
        zflag = 1 - zflag;
        updatezero(zflag);
      }

      if ( abs(xs - 165) < 22) {  // store mode
        sflag = 1 - sflag;
        updatestore(sflag);
      }

      if ( abs(xs - 205) < 22) {  // recall mode
        rflag = 1 - rflag;
        updaterecall(rflag);
      }

    }
  } else { // store or recall or zero are on...

    if (xs > 210 && ys > 130) {   // store/recall selection
      int sel;
      if (abs(ys - 280) < 30) sel = 0;
      if (abs(ys - 220) < 30) sel = 1;
      if (abs(ys - 160) < 30) sel = 2;
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
