<?php
require_once __DIR__ . '/../config/database.php';

$error = '';
$success = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = $_POST['username'] ?? '';
    $password = $_POST['password'] ?? '';
    $email = $_POST['email'] ?? '';
    $user_type = $_POST['user_type'] ?? 'patient';
    $first_name = $_POST['first_name'] ?? '';
    $last_name = $_POST['last_name'] ?? '';
    
    if ($username && $password && $first_name && $last_name) {
        try {
            $pdo = getDatabaseConnection();
            $hashed_password = password_hash($password, PASSWORD_DEFAULT);
            
            // Create user
            $stmt = $pdo->prepare("INSERT INTO users (username, password, email, user_type) VALUES (?, ?, ?, ?)");
            $stmt->execute([$username, $hashed_password, $email, $user_type]);
            $user_id = $pdo->lastInsertId();
            
            // Create patient or doctor record
            if ($user_type === 'patient') {
                $stmt = $pdo->prepare("INSERT INTO patients (user_id, first_name, last_name) VALUES (?, ?, ?)");
                $stmt->execute([$user_id, $first_name, $last_name]);
            } else {
                $specialization = $_POST['specialization'] ?? '';
                $stmt = $pdo->prepare("INSERT INTO doctors (user_id, first_name, last_name, specialization) VALUES (?, ?, ?, ?)");
                $stmt->execute([$user_id, $first_name, $last_name, $specialization]);
            }
            
            $success = "Registration successful! Please login.";
        } catch (Exception $e) {
            $error = "Registration failed: " . $e->getMessage();
        }
    } else {
        $error = "Please fill all required fields";
    }
}
?>
<!DOCTYPE html>
<html>
<head>
    <title>Register - Hospital Management System</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="container">
        <h2>Register</h2>
        <?php if ($error): ?><div class="error"><?= htmlspecialchars($error) ?></div><?php endif; ?>
        <?php if ($success): ?><div class="success"><?= htmlspecialchars($success) ?></div><?php endif; ?>
        <form method="POST">
            <label>User Type:</label>
            <select name="user_type" required>
                <option value="patient">Patient</option>
                <option value="doctor">Doctor</option>
            </select>
            <label>Username:</label>
            <input type="text" name="username" required>
            <label>Password:</label>
            <input type="password" name="password" required>
            <label>Email:</label>
            <input type="email" name="email">
            <label>First Name:</label>
            <input type="text" name="first_name" required>
            <label>Last Name:</label>
            <input type="text" name="last_name" required>
            <div id="specialization-field" style="display:none;">
                <label>Specialization:</label>
                <input type="text" name="specialization" placeholder="e.g., Cardiologist">
            </div>
            <button type="submit">Register</button>
        </form>
        <p><a href="login.php">Already have an account? Login</a></p>
    </div>
    <script>
        document.querySelector('select[name="user_type"]').addEventListener('change', function() {
            document.getElementById('specialization-field').style.display = 
                this.value === 'doctor' ? 'block' : 'none';
        });
    </script>
</body>
</html>

