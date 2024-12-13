const int enaPin = 9;      // Pin PWM untuk kecepatan
const int in1Pin = 7;      // Pin arah motor
const int in2Pin = 8;      // Pin arah motor

volatile unsigned long pulseCount = 0; // Variabel untuk menghitung jumlah pulsa
unsigned long previousMillis = 0;      // Waktu sebelumnya untuk pembaruan
const unsigned long interval = 1000;   // Interval pembaruan dalam milidetik (1 detik)

int targetRps = 0;  // Variabel untuk menyimpan target RPS (integer)
int rpm = 0;         // Variabel untuk menghitung RPM
int rps = 0;         // Variabel untuk menghitung RPS
int pwmValue = 0;    // Variabel untuk menyimpan nilai PWM

float kp = 0.5;      // Faktor Proportional
float ki = 0.09;      // Faktor Integral
float kd = 0.01;    // Faktor Derivative

int lastError = 0;
float integral = 0;

void setup() {
  Serial.begin(9600); 
  Serial.println("Ketik target RPS di Serial Monitor:");

  pinMode(enaPin, OUTPUT);
  pinMode(in1Pin, OUTPUT);
  pinMode(in2Pin, OUTPUT);

  pinMode(2, INPUT_PULLUP); // Pin input untuk sensor
  attachInterrupt(digitalPinToInterrupt(2), countPulse, RISING); 
}

void loop() {
  if (Serial.available() > 0) {
    String input = Serial.readStringUntil('\n');
    input.trim();

    if (input == "F") {
      digitalWrite(in1Pin, HIGH);
      digitalWrite(in2Pin, LOW);
      Serial.println("Motor akan bergerak maju.");
    } else if (input == "B") {
      digitalWrite(in1Pin, LOW);
      digitalWrite(in2Pin, HIGH);
      Serial.println("Motor akan bergerak mundur.");
    } else if (input == "STOP") {
      analogWrite(enaPin, 0); 
      Serial.println("Motor berhenti.");
    } else if (input.startsWith("RUN")) {
      targetRps = input.substring(3).toInt();
      adjustPwmBasedOnRps(targetRps);
    }
  }

  unsigned long currentMillis = millis(); 
  if (currentMillis - previousMillis >= interval) {
    readSensor();
    previousMillis = currentMillis;

    // Kirim RPS ke Processing
    Serial.println(rps); // Kirim hanya nilai RPS
  }
}

void countPulse() {
  pulseCount++; 
}

void readSensor() {
  rpm = (pulseCount / 12.0) * (60000 / interval); // Hitung RPM
  rps = rpm / 60; // Hitung RPS (Rotasi per detik)
  pulseCount = 0;
}

void adjustPwmBasedOnRps(int targetRps) {
  int error = targetRps - rps;
  integral += error;
  int derivative = error - lastError;
  lastError = error;

  pwmValue = kp * error + ki * integral + kd * derivative;
  pwmValue = constrain(pwmValue, 0, 255);
  analogWrite(enaPin, pwmValue);

  Serial.print("PWM: ");
  Serial.println(pwmValue);
}