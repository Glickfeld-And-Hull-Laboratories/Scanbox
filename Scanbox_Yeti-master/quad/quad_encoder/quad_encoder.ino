
#include <Encoder.h>

Encoder myEnc(2, 3);

void setup() {
  Serial.begin(1000000);
  Serial1.begin(1000000);
  myEnc.write(0);
}

void loop() {
  long pos;
  byte *b,m;

  b = (byte *) &pos;  
  pos = myEnc.read();

  if (Serial.available()) {
    m = Serial.read();
    if(m>0) {
      myEnc.write(0);    // zero the position
      pos = 0;
    } 
    else {
      Serial.write((byte *) &pos,4);
    }
  }

  if(Serial1.available()) {
    Serial1.read();
    Serial1.write((byte *) & pos,4);
  }
  
}



