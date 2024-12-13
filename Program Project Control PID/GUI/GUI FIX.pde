import processing.serial.*; //untuk komunikasi antara Processing dan Arduino

Serial port; //untuk mengelola komunikasi serial
int targetRps = 0;
float kp = 0.0, ki = 0.0, kd = 0.0;

// Variabel untuk grafik RPS
ArrayList<Float> rpsData = new ArrayList<Float>(); // Menyimpan nilai RPS (kecepatan motor) untuk ditampilkan pada grafik.
ArrayList<Float> timeData = new ArrayList<Float>(); // Menyimpan waktu terkait data RPS.
float graphX = 50, graphY = 100, graphWidth = 300, graphHeight = 100; //Variabel untuk menentukan posisi dan ukuran
int maxGraphPoints = 100; // jumlah maksimum data
float startTime; // Waktu mulai pengambilan data
float lastTime = 0; // WWaktu sebelumnya untuk menghitung interval waktu antar data.

// Variabel untuk error dan nilai RPS yang sebenarnya
float currentRps = 0;
float error = 0;

void setup() {
  size(800, 700); // Ukuran window GUI

  // Inisialisasi komunikasi serial
  String portName = Serial.list()[0]; // Pilih port pertama (ubah sesuai kebutuhan) dan menghubungkannya dengan baud rate 9600.
  port = new Serial(this, portName, 9600); 

  startTime = millis(); // Mencatat waktu mulai
}

void draw() {
  background(220); // Background abu-abu

  // Header
  fill(0);
  textSize(20);
  textAlign(CENTER);
  text("Kontrol Motor PID", width / 2, 30);

  // Grafik RPS
  drawGraph();

  // Slider untuk Target RPS
  textAlign(LEFT);
  textSize(14);
  text("Target RPS: " + targetRps, 50, 240);
  rect(50, 250, 300, 20);
  fill(100, 200, 100);
  rect(50, 250, map(targetRps, 0, 100, 0, 300), 20);
  fill(0);

  // Slider untuk Kp
  text("Kp: " + nf(kp, 1, 2), 50, 310);
  rect(50, 320, 300, 20);
  fill(100, 200, 100);
  rect(50, 320, map(kp, 0, 1, 0, 300), 20);
  fill(0);

  // Slider untuk Ki
  text("Ki: " + nf(ki, 1, 2), 50, 380);
  rect(50, 390, 300, 20);
  fill(100, 200, 100);
  rect(50, 390, map(ki, 0, 1, 0, 300), 20);
  fill(0);

  // Slider untuk Kd
  text("Kd: " + nf(kd, 1, 3), 50, 450);
  rect(50, 460, 300, 20);
  fill(100, 200, 100);
  rect(50, 460, map(kd, 0, 1, 0, 300), 20);
  fill(0);

  // Tombol kontrol motor
  textSize(16);
  textAlign(CENTER);
  fill(200, 100, 100);
  rect(50, 500, 120, 40);
  fill(0);
  text("MAJU", 110, 530);

  fill(100, 100, 200);
  rect(230, 500, 120, 40);
  fill(0);
  text("MUNDUR", 290, 530);

  fill(100, 200, 100);
  rect(50, 560, 120, 40);
  fill(0);
  text("RUN", 110, 590);

  fill(200, 100, 100);
  rect(230, 560, 120, 40);
  fill(0);
  text("STOP", 290, 590);

  // Menampilkan nilai RPS dan error di samping grafik
  fill(0);
  textSize(14);
  textAlign(LEFT);
  text("RPS Aktual: " + nf(currentRps, 1, 2), graphX + graphWidth + 20, graphY + 20);
  text("Error: " + nf(error, 1, 2), graphX + graphWidth + 20, graphY + 40);
}

void mousePressed() {
  // Cek apakah slider Target RPS diubah
  if (mouseY > 250 && mouseY < 270 && mouseX > 50 && mouseX < 350) {
    targetRps = int(map(mouseX, 50, 350, 0, 100));
    port.write("RUN" + targetRps + "\n");
  }

  // Cek apakah slider Kp diubah
  if (mouseY > 320 && mouseY < 340 && mouseX > 50 && mouseX < 350) {
    kp = map(mouseX, 50, 350, 0, 1);
    port.write("P" + nf(kp, 1, 2) + "\n");
  }

  // Cek apakah slider Ki diubah
  if (mouseY > 390 && mouseY < 410 && mouseX > 50 && mouseX < 350) {
    ki = map(mouseX, 50, 350, 0, 1);
    port.write("I" + nf(ki, 1, 2) + "\n");
  }

  // Cek apakah slider Kd diubah
  if (mouseY > 460 && mouseY < 480 && mouseX > 50 && mouseX < 350) {
    kd = map(mouseX, 50, 350, 0, 1);
    port.write("D" + nf(kd, 1, 3) + "\n");
  }

  // Cek tombol kontrol motor
  if (mouseX > 50 && mouseX < 170 && mouseY > 500 && mouseY < 540) {
    port.write("F\n"); // Kirim perintah maju
  } else if (mouseX > 230 && mouseX < 350 && mouseY > 500 && mouseY < 540) {
    port.write("B\n"); // Kirim perintah mundur
  } else if (mouseX > 50 && mouseX < 170 && mouseY > 560 && mouseY < 600) {
    port.write("RUN" + targetRps + "\n"); // Kirim perintah menjalankan motor
  } else if (mouseX > 230 && mouseX < 350 && mouseY > 560 && mouseY < 600) {
    port.write("STOP\n"); // Kirim perintah menghentikan motor
  }
}

void serialEvent(Serial port) {
  // Baca data dari serial dan update grafik
  String input = trim(port.readStringUntil('\n')); // pastikan data diakhiri dengan newline
  if (input != null && input.length() > 0) {
    try {
      // Coba untuk mengubah input menjadi float
      currentRps = Float.parseFloat(input);
      error = targetRps - currentRps; // Menghitung error

      float currentTime = (millis() - startTime) / 1000.0; // Hitung waktu dalam detik
      rpsData.add(currentRps);
      timeData.add(currentTime);

      // Membatasi jumlah data yang ditampilkan pada grafik
      if (rpsData.size() > maxGraphPoints) {
        rpsData.remove(0);
        timeData.remove(0);
      }
    } catch (NumberFormatException e) {
      println("Data tidak valid: " + input);  // Menampilkan pesan jika terjadi error
    }
  }
}

void drawGraph() {
  fill(255);
  rect(graphX, graphY, graphWidth, graphHeight);
  stroke(0);
  noFill();
  beginShape();
  
  // Pastikan untuk memetakan waktu pada sumbu X
  for (int i = 0; i < rpsData.size(); i++) {
    float x = map(timeData.get(i), 0, timeData.get(timeData.size() - 1), graphX, graphX + graphWidth);
    float y = map(rpsData.get(i), 0, 100, graphY + graphHeight, graphY);
    vertex(x, y);
  }
  endShape();
  
  fill(0);
  textAlign(LEFT);
  text("RPS Response vs Time", graphX, graphY - 10);
}
