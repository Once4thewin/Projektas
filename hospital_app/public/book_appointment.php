<?php
session_start();
require_once __DIR__ . '/../config/database.php';

if (!isset($_SESSION['user_id']) || $_SESSION['user_type'] !== 'patient') {
    header('Location: login.php');
    exit;
}

$pdo = getDatabaseConnection();
$success = '';
$error = '';

// Get patient ID
$stmt = $pdo->prepare("SELECT id FROM patients WHERE user_id = ?");
$stmt->execute([$_SESSION['user_id']]);
$patient = $stmt->fetch();
$patient_id = $patient['id'];

// Get selected doctor or list all doctors
$doctor_id = $_GET['doctor_id'] ?? null;
$doctors = [];

if ($doctor_id) {
    $stmt = $pdo->prepare("SELECT * FROM doctors WHERE id = ?");
    $stmt->execute([$doctor_id]);
    $selected_doctor = $stmt->fetch();
} else {
    $stmt = $pdo->prepare("SELECT * FROM doctors");
    $stmt->execute();
    $doctors = $stmt->fetchAll();
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $doctor_id = $_POST['doctor_id'] ?? '';
    $appointment_date = $_POST['appointment_date'] ?? '';
    $notes = $_POST['notes'] ?? '';
    
    if ($doctor_id && $appointment_date) {
        try {
            $stmt = $pdo->prepare("
                INSERT INTO appointments (patient_id, doctor_id, appointment_date, status, notes)
                VALUES (?, ?, ?, 'scheduled', ?)
            ");
            $stmt->execute([$patient_id, $doctor_id, $appointment_date, $notes]);
            $success = "Appointment booked successfully!";
        } catch (Exception $e) {
            $error = "Failed to book appointment: " . $e->getMessage();
        }
    } else {
        $error = "Please fill all required fields";
    }
}
?>
<!DOCTYPE html>
<html>
<head>
    <title>Book Appointment - Hospital Management System</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="header">
        <h1>Book Appointment</h1>
        <a href="patient_dashboard.php">Back to Dashboard</a>
    </div>
    <div class="container">
        <?php if ($error): ?><div class="error"><?= htmlspecialchars($error) ?></div><?php endif; ?>
        <?php if ($success): ?><div class="success"><?= htmlspecialchars($success) ?></div><?php endif; ?>
        
        <form method="POST">
            <label>Doctor:</label>
            <?php if ($selected_doctor): ?>
                <input type="hidden" name="doctor_id" value="<?= $selected_doctor['id'] ?>">
                <p>Dr. <?= htmlspecialchars($selected_doctor['first_name'] . ' ' . $selected_doctor['last_name']) ?> 
                   (<?= htmlspecialchars($selected_doctor['specialization']) ?>)</p>
            <?php else: ?>
                <select name="doctor_id" required>
                    <option value="">Select Doctor</option>
                    <?php foreach ($doctors as $doc): ?>
                    <option value="<?= $doc['id'] ?>">
                        Dr. <?= htmlspecialchars($doc['first_name'] . ' ' . $doc['last_name']) ?> 
                        (<?= htmlspecialchars($doc['specialization']) ?>)
                    </option>
                    <?php endforeach; ?>
                </select>
            <?php endif; ?>
            
            <label>Appointment Date & Time:</label>
            <input type="datetime-local" name="appointment_date" required>
            
            <label>Notes (optional):</label>
            <textarea name="notes"></textarea>
            
            <button type="submit">Book Appointment</button>
        </form>
    </div>
</body>
</html>

