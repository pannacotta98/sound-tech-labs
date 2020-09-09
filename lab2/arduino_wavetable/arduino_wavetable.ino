/* Arduino Realtime Audio Processing
   2 ADC 8-Bit Mode
   analog input 0 is used to sample the audio signal
   analog input 1 is used to control an audio effect
   PWM DAC with Timer2 as analog output
   
   Original idea:
   KHM 2008 / Lab3/  Martin Nawrath nawrath@khm.de
   Kunsthochschule fuer Medien Koeln
   Academy of Media Arts Cologne
    
   Redeveloped by Niklas Rönnberg
   Linköping university
   For the course Ljudteknik 1
 */

// Inkludera math, för att kunna använda M_PI, round osv
#include <math.h>

// cbi betyder Clear Bit i I/O-registret och sätter specifik bit till 0
// sbi betyder Set Bit i I/O-registret och sätter specifik bit till 1
// Definiera cbi och sbi
#define cbi(sfr, bit) (_SFR_BYTE(sfr) &= ~_BV(bit))
#define sbi(sfr, bit) (_SFR_BYTE(sfr) |= _BV(bit))

// Definiera globala variabler som kommer att användas till delning av interruptservicen
boolean div32;
boolean div16;

// Definiera globala variabler
volatile boolean sampleFlag; // Sampleflaggan
volatile byte badc0; // Det samplade ljudvärdet, byte AD-konverterare kanal 0
volatile byte badc1; // Det samplade potentiometervärdet, kanal 1
volatile byte ibb; // Global interruptvariabel

int bufferIndex; // Index i SRAM buffer
int bufferIndex2; // Alternativ index

int soundSampleFromADC; // Variabel för att läsa samplevärde från ADCn
int soundSampleFromSramBuffer; // Variabel för att läsa samplevärde från SRAM buffer
byte sramBufferSampleValue; // sparat samplevärde i SRAM buffer

byte sramBuffer[512]; // SRAM buffer, "ljudminne", 8-bitar




// setup() är en funktion som körs en, och endast en gång, när Arduinot startas eller resetas.
// Den används för att initiera variabler, pinmodes etc.
// Void används då funktionen inte förväntas returnera något.
void setup()
{
  fillSramBufferWithWaveTable(); // Fyll SRAM-bufferten
  Serial.begin(57600);        // connect to the serial port
  // Atmega32 har tre register för ADC - ADCSRA , ADMUX and ADCW
  // Det är snabbare att manipulera portar och pinnar med AVR-kod
  // jämfört mot Arduinos digitalWrite()-funktion.

  // set adc prescaler to 64 for 19kHz sampling frequency
  // ADCSRA står för ADC Control and Status Register A
  cbi(ADCSRA, ADPS2);
  sbi(ADCSRA, ADPS1);
  sbi(ADCSRA, ADPS0);

  // ADMUX är lågnivåskontroll av analog-till-digital-konverterarna.
  // ADMUX är ett 8-bitars tal som innehåller ADCH-register
  // ADMUX står för ADC Multiplexer Selection Register
  sbi(ADMUX,ADLAR);  // 8-Bit ADC in ADCH Register
  sbi(ADMUX,REFS0);  // VCC Reference
  cbi(ADMUX,REFS1);
  cbi(ADMUX,MUX0);   // Set Input Multiplexer to Channel 0
  cbi(ADMUX,MUX1);
  cbi(ADMUX,MUX2);
  cbi(ADMUX,MUX3);

  // TCCRnA och TCCRnB är kontrollregister för timer/räknare
  // Timer2s PWM-mode sätts till fast PWM
  cbi(TCCR2A, COM2A0); // Toggle on Compare Match
  sbi(TCCR2A, COM2A1);
  sbi(TCCR2A, WGM20); // waveform generation mode
  sbi(TCCR2A, WGM21);
  cbi(TCCR2B, WGM22);

  // Timer2 Clock Prescaler to : 1 
  sbi(TCCR2B, CS20);
  cbi(TCCR2B, CS21);
  cbi(TCCR2B, CS22);

  // Timer2 PWM Port Enable
  sbi(DDRB,3); // Sätt digitalpin 11 till PWM för att användas som analogutgång (OCR2A)

  cbi(TIMSK0,TOIE0); // Inaktiverar Timer0 Interrupt
  sbi(TIMSK2,TOIE2); // Aktiverar Timer2 Interrupt
  
  // Tilldela variabel soundSampleFromADC ett samplevärde från ADCn
  soundSampleFromADC = badc0;  
}




// loop() är en funktion som körs om och om igen efter att Arduinot har startats och setup() har 
// initierat Arduinot. Detta är huvudfunktionen och den körs så snabbt/ofta det går enligt
// klockfrekvensen i Arduinot. Normal klockfrekvens är 16MHz.
void loop()
{
  // Vänta på samplevärde från analog-till-digital-konverteraren
  // en samplingscykel 15625 KHz = 65 mikrosekunder 
  while (!sampleFlag) {
  }

  bufferIndex += (badc1 != 0) ? badc1 : 1;
  bufferIndex %= 512;

  bufferIndex2 += 3 * ((badc1 != 0) ? badc1 : 1);
  bufferIndex2 %= 512;

  //byte sramBufferSampleValue = sramBuffer[bufferIndex];
  byte sramBufferSampleValue = 127 + (((sramBuffer[bufferIndex]-127)
                                     + (sramBuffer[bufferIndex2]-127))) / 2;

  //Serial.println(sramBufferSampleValue);
  OCR2A = sramBufferSampleValue;
  
  sampleFlag = false;  // Sätt samplingsflaggan till false för att invänta nästa sample
}




// Funktion för att fylla SRAM buffern med en vågform
void fillSramBufferWithWaveTable(){
  // SQUARE
  /*float soundValue = 0;
  for (int i = 0; i < sizeof(sramBuffer); ++i) {
    if (i < 255) {
      soundValue = 192;
    } else {
      soundValue = 64;
    }
    sramBuffer[i] = soundValue;
  }*/

  // SAWTOOTH
  /*float soundValue = 255;
  for (int i = 0; i < sizeof(sramBuffer); ++i) {
    soundValue = soundValue - 255.0f / sizeof(sramBuffer);
    sramBuffer[i] = soundValue;
  }*/

  // TRIANGLE
  /*float soundValue = 255;
  for (int i = 0; i < sizeof(sramBuffer) / 2; ++i) {
    soundValue = soundValue - 255.0f / (sizeof(sramBuffer) / 2);
    sramBuffer[i] = floor(soundValue);
  }
  for (int i = sizeof(sramBuffer) / 2; i < sizeof(sramBuffer); ++i) {
    soundValue = soundValue + 255.0f / (sizeof(sramBuffer) / 2);
    sramBuffer[i] = ceil(soundValue);
  }*/


  // TRIANGLE 2
  /*float soundValue = 255;
  for (int i = 0; i < sizeof(sramBuffer) / 2; ++i) {
    soundValue = soundValue - 255.0f / (sizeof(sramBuffer) / 2);
    sramBuffer[i] = round(soundValue);
  }
  for (int i = sizeof(sramBuffer) / 2; i < sizeof(sramBuffer); ++i) {
    soundValue = soundValue + 255.0f / (sizeof(sramBuffer) / 2);
    sramBuffer[i] = round(soundValue);
  }*/
  

  // SINE
  /*float soundValue = 0;
  float deltaSoundValue = (2.0f * M_PI) / sizeof(sramBuffer);
  for (int i = 0; i < sizeof(sramBuffer); ++i) {
    float sinusSample = 127.0f * sin(soundValue) + 127.0f;
    soundValue += deltaSoundValue;
    sramBuffer[i] = sinusSample;
  }*/

  // MIXED SINE AND SQUARE
  float soundValue = 0;
  float deltaSoundValue = (2.0f * M_PI) / sizeof(sramBuffer);
  
  for (int i = 0; i < sizeof(sramBuffer); ++i) {
    float sinusSample = 127.0f * sin(soundValue);
    soundValue += deltaSoundValue;

    float squareValue = 64 * ((i < 255) ? 1 : -1);
    sramBuffer[i] = 127.0f + (sinusSample + squareValue) / 2;
  }
}




// Timer2, interruptservice 62.5 KHz
// Här samplas analogingång 0 (ljudingången) och analogingång 1 (potentiometern) 16Mhz / 256 / 2 / 2 = 15625 Hz
ISR(TIMER2_OVF_vect) {
  div32=!div32; // Dela timer2s frekvens med 2 till 31.25kHz genom att toggla div32 mellan 0 och 1
                // och gör bara något när div32 är 1
  if (div32){ 
    div16=!div16; //  Dela timer2 igen på samma sätt
    if (div16) {
      // Sampla kanal 0 och 1 varannan gång så att båda kanalerna samplas i 15.6kHz
      badc0 = ADCH; // Sampla ADC kanal 0
      sbi(ADMUX,MUX0); // Sätt multiplex till kanal 1 (med hjälp av sbi)
      sampleFlag = true; // Sätt samplingsflaggan till true då ljudet har samplats en gång
    }
    else
    {
      badc1 = ADCH; // Sampla ADC kanal 1
      cbi(ADMUX,MUX0); // Sätt multiplex till kanal 0 (med hjälp av cbi)
    }
    ibb++; // Kort fördröjning innan nästa conversion
    ibb--; 
    ibb++; 
    ibb--;
    sbi(ADCSRA,ADSC); // Starta nästa conversion
  }
}
