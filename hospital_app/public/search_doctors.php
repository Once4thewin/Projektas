<?php
session_start();
require_once __DIR__ . '/../config/database.php';

if (!isset($_SESSION['user_id'])) {
    header('Location: login.php');
    exit;
}

$pdo = getDatabaseConnection();
$doctors = [];
$search_term = $_GET['search'] ?? '';
$search_type = $_GET['search_type'] ?? 'name';

if ($search_term) {
    if ($search_type === 'name') {
        $stmt = $pdo->prepare("
            SELECT d.*, u.email 
            FROM doctors d
            JOIN users u ON d.user_id = u.id
            WHERE d.first_name LIKE ? OR d.last_name LIKE ?
        ");
        $search_pattern = "%$search_term%";
        $stmt->execute([$search_pattern, $search_pattern]);
    } elseif ($search_type === 'specialization') {
        $stmt = $pdo->prepare("
            SELECT d.*, u.email 
            FROM doctors d
            JOIN users u ON d.user_id = u.id
            WHERE d.specialization LIKE ?
        ");
        $search_pattern = "%$search_term%";
        $stmt->execute([$search_pattern]);
    }
    $doctors = $stmt->fetchAll();
} else {
    // Show all doctors
    $stmt = $pdo->prepare("
        SELECT d.*, u.email 
        FROM doctors d
        JOIN users u ON d.user_id = u.id
    ");
    $stmt->execute();
    $doctors = $stmt->fetchAll();
}
?>
<!DOCTYPE html>
<html>
<head>
    <title>Search Doctors - Hospital Management System</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="header">
        <h1>Search Doctors</h1>
        <a href="patient_dashboard.php">Back to Dashboard</a>
    </div>
    <div class="container">
        <form method="GET" class="search-form">
            <input type="text" name="search" placeholder="Search..." value="<?= htmlspecialchars($search_term) ?>">
            <select name="search_type">
                <option value="name" <?= $search_type === 'name' ? 'selected' : '' ?>>By Name</option>
                <option value="specialization" <?= $search_type === 'specialization' ? 'selected' : '' ?>>By Specialization</option>
            </select>
            <button type="submit">Search</button>
        </form>
        
        <h2>Available Doctors</h2>
        <table>
            <tr>
                <th>Name</th>
                <th>Specialization</th>
                <th>Phone</th>
                <th>Actions</th>
            </tr>
            <?php foreach ($doctors as $doctor): ?>
            <tr>
                <td>Dr. <?= htmlspecialchars($doctor['first_name'] . ' ' . $doctor['last_name']) ?></td>
                <td><?= htmlspecialchars($doctor['specialization'] ?? 'N/A') ?></td>
                <td><?= htmlspecialchars($doctor['phone'] ?? 'N/A') ?></td>
                <td><a href="book_appointment.php?doctor_id=<?= $doctor['id'] ?>">Book Appointment</a></td>
            </tr>
            <?php endforeach; ?>
        </table>
    </div>
</body>
</html>

