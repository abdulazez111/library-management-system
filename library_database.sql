-- =============================================
-- LIBRARY MANAGEMENT SYSTEM DATABASE
-- =============================================

CREATE DATABASE IF NOT EXISTS library_db;
USE library_db;

-- =============================================
-- CREATE TABLES
-- =============================================

-- جدول المؤلفين
CREATE TABLE authors(
    author_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    biography TEXT,
    birth_date DATE,
    nationality VARCHAR(50),
    email VARCHAR(100) UNIQUE
);

-- جدول الكتب
CREATE TABLE books(
    book_id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    isbn VARCHAR(20) UNIQUE,
    publication_year INT,
    category VARCHAR(100),
    publisher VARCHAR(100),
    total_copies INT DEFAULT 1,
    available_copies INT DEFAULT 1
);

-- جدول العلاقة بين الكتب والمؤلفين (Many-to-Many)
CREATE TABLE book_authors(
    book_id INT,
    author_id INT,
    PRIMARY KEY (book_id, author_id),
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
    FOREIGN KEY (author_id) REFERENCES authors(author_id) ON DELETE CASCADE
);

-- جدول الأعضاء
CREATE TABLE members(
    member_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    address TEXT,
    membership_date DATE DEFAULT (CURDATE()),
    status ENUM('active', 'inactive') DEFAULT 'active'
);

-- جدول الاستعارات
CREATE TABLE borrowings(
    borrow_id INT PRIMARY KEY AUTO_INCREMENT,
    book_id INT,
    member_id INT,
    borrow_date DATE DEFAULT (CURDATE()),
    due_date DATE NOT NULL,
    return_date DATE,
    status ENUM('borrowed', 'returned', 'overdue') DEFAULT 'borrowed',
    FOREIGN KEY (book_id) REFERENCES books(book_id),
    FOREIGN KEY (member_id) REFERENCES members(member_id)
);

-- جدول الحجوزات
CREATE TABLE reservations(
    reservation_id INT PRIMARY KEY AUTO_INCREMENT,
    book_id INT,
    member_id INT,
    reservation_date DATE DEFAULT (CURDATE()),
    status ENUM('pending', 'fulfilled', 'cancelled') DEFAULT 'pending',
    FOREIGN KEY (book_id) REFERENCES books(book_id),
    FOREIGN KEY (member_id) REFERENCES members(member_id)
);

-- جدول الغرامات
CREATE TABLE fines(
    fine_id INT PRIMARY KEY AUTO_INCREMENT,
    borrow_id INT,
    member_id INT,
    amount DECIMAL(10,2),
    reason VARCHAR(255),
    payment_status ENUM('paid', 'unpaid') DEFAULT 'unpaid',
    FOREIGN KEY (borrow_id) REFERENCES borrowings(borrow_id),
    FOREIGN KEY (member_id) REFERENCES members(member_id)
);

-- =============================================
-- INSERT SAMPLE DATA
-- =============================================

-- بيانات المؤلفين
INSERT INTO authors (name, biography, birth_date, nationality, email) VALUES
('أحمد محمد', 'روائي سعودي مشهور، له العديد من الأعمال الأدبية', '1975-03-15', 'سعودي', 'ahmed@example.com'),
('فاطمة عبدالله', 'كاتبة قصص أطفال، حاصلة على عدة جوائز', '1980-07-22', 'سعودية', 'fatima@example.com'),
('خالد السعدي', 'باحث في التاريخ الإسلامي', '1965-11-08', 'سعودي', 'khaled@example.com'),
('يوسف القرشي', 'شاعر وكاتب مسرحي', '1978-05-30', 'سعودي', 'yousef@example.com');

-- بيانات الكتب
INSERT INTO books (title, isbn, publication_year, category, publisher, total_copies, available_copies) VALUES
('الأيام الأخيرة', '978-603-01-1234-1', 2020, 'رواية', 'دار النشر العربية', 5, 5),
('حديقة الأحلام', '978-603-01-1235-8', 2019, 'أطفال', 'مكتبة العبيكان', 3, 3),
('تاريخ المملكة', '978-603-01-1236-5', 2015, 'تاريخ', 'الدار الوطنية', 2, 2),
('أشعار من القلب', '978-603-01-1237-2', 2021, 'شعر', 'المركز الثقافي', 4, 4);

-- بيانات الأعضاء
INSERT INTO members (name, email, phone, address, membership_date, status) VALUES
('سارة الخالد', 'sara@example.com', '0551234567', 'الرياض - حي الملز', CURDATE(), 'active'),
('محمد العتيبي', 'mohammed@example.com', '0557654321', 'جدة - حي الصفا', CURDATE(), 'active'),
('نورة الراشد', 'nora@example.com', '0551122334', 'الدمام - حي الفيصل', CURDATE(), 'active');

-- ربط الكتب بالمؤلفين
INSERT INTO book_authors (book_id, author_id) VALUES
(1, 1),  -- الأيام الأخيرة - أحمد محمد
(2, 2),  -- حديقة الأحلام - فاطمة عبدالله
(3, 3),  -- تاريخ المملكة - خالد السعدي
(4, 4);  -- أشعار من القلب - يوسف القرشي

-- بيانات الاستعارات
INSERT INTO borrowings (book_id, member_id, borrow_date, due_date, return_date, status) VALUES
(1, 1, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 14 DAY), NULL, 'borrowed'),
(2, 2, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 14 DAY), NULL, 'borrowed');

-- =============================================
-- STORED PROCEDURES
-- =============================================

DELIMITER //

-- Procedure إضافة استعارة جديدة
CREATE PROCEDURE AddBorrowing(
    IN p_book_id INT,
    IN p_member_id INT,
    IN p_due_days INT
)
BEGIN
    DECLARE book_available INT;
    DECLARE member_active VARCHAR(20);
    DECLARE existing_borrowings INT;
    
    -- التحقق من حالة العضو
    SELECT status INTO member_active FROM members WHERE member_id = p_member_id;
    
    -- التحقق من عدد استعارات العضو النشطة
    SELECT COUNT(*) INTO existing_borrowings 
    FROM borrowings 
    WHERE member_id = p_member_id AND status = 'borrowed';
    
    -- التحقق من توفر الكتاب
    SELECT available_copies INTO book_available FROM books WHERE book_id = p_book_id;
    
    -- إذا كان العضو غير نشط
    IF member_active != 'active' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'العضو غير نشط، لا يمكن الاستعارة';
    
    -- إذا تجاوز العضو الحد المسموح (3 كتب)
    ELSEIF existing_borrowings >= 3 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'تجاوزت الحد المسموح للاستعارات (3 كتب)';
    
    -- إذا الكتاب غير متاح
    ELSEIF book_available <= 0 THEN
        -- عرض كتب بديلة مقترحة
        SELECT 'الكتاب غير متاح،以下是一些الكتب المقترحة:' AS message;
        
        SELECT b.book_id, b.title, a.name as author_name, b.available_copies
        FROM books b
        JOIN book_authors ba ON b.book_id = ba.book_id
        JOIN authors a ON ba.author_id = a.author_id
        WHERE b.category = (SELECT category FROM books WHERE book_id = p_book_id)
          AND b.available_copies > 0
          AND b.book_id != p_book_id
        LIMIT 5;
        
    -- إذا كل الشروط متاحة
    ELSE
        -- إضافة الاستعارة
        INSERT INTO borrowings (book_id, member_id, borrow_date, due_date, status)
        VALUES (p_book_id, p_member_id, CURDATE(), DATE_ADD(CURDATE(), INTERVAL p_due_days DAY), 'borrowed');
        
        -- تحديث عدد النسخ المتاحة
        UPDATE books SET available_copies = available_copies - 1 WHERE book_id = p_book_id;
        
        SELECT 'تمت الاستعارة بنجاح' AS message;
    END IF;
    
END //

-- Procedure تسجيل إرجاع كتاب
CREATE PROCEDURE ReturnBook(
    IN p_borrow_id INT
)
BEGIN
    DECLARE v_book_id INT;
    DECLARE v_return_date DATE;
    
    -- الحصول على book_id وتاريخ الإرجاع
    SELECT book_id, return_date INTO v_book_id, v_return_date 
    FROM borrowings WHERE borrow_id = p_borrow_id;
    
    -- إذا تم الإرجاع مسبقاً
    IF v_return_date IS NOT NULL THEN
        SELECT 'هذا الكتاب تم إرجاعه مسبقاً' AS message;
    ELSE
        -- تحديث تاريخ الإرجاع والحالة
        UPDATE borrowings 
        SET return_date = CURDATE(), status = 'returned' 
        WHERE borrow_id = p_borrow_id;
        
        -- زيادة النسخ المتاحة
        UPDATE books SET available_copies = available_copies + 1 
        WHERE book_id = v_book_id;
        
        -- التحقق من التأخير
        IF CURDATE() > (SELECT due_date FROM borrowings WHERE borrow_id = p_borrow_id) THEN
            UPDATE borrowings SET status = 'overdue' WHERE borrow_id = p_borrow_id;
            SELECT 'تم الإرجاع مع ملاحظة: هناك تأخير في الإرجاع' AS message;
        ELSE
            SELECT 'تم إرجاع الكتاب بنجاح' AS message;
        END IF;
    END IF;
    
END //

-- Procedure البحث عن كتب
CREATE PROCEDURE SearchBooks(
    IN p_search_term VARCHAR(255)
)
BEGIN
    SELECT DISTINCT b.book_id, b.title, b.isbn, b.publication_year, 
           b.category, b.publisher, b.available_copies,
           GROUP_CONCAT(a.name SEPARATOR '، ') as authors
    FROM books b
    LEFT JOIN book_authors ba ON b.book_id = ba.book_id
    LEFT JOIN authors a ON ba.author_id = a.author_id
    WHERE b.title LIKE CONCAT('%', p_search_term, '%')
       OR a.name LIKE CONCAT('%', p_search_term, '%')
       OR b.category LIKE CONCAT('%', p_search_term, '%')
    GROUP BY b.book_id
    ORDER BY b.available_copies DESC;
END //

DELIMITER ;

-- =============================================
-- CREATE VIEWS
-- =============================================

-- عرض الكتب المتاحة مع معلومات المؤلفين
CREATE VIEW AvailableBooks AS
SELECT 
    b.book_id,
    b.title,
    b.isbn,
    b.publication_year,
    b.category,
    b.publisher,
    b.available_copies,
    GROUP_CONCAT(a.name SEPARATOR '، ') AS authors
FROM books b
LEFT JOIN book_authors ba ON b.book_id = ba.book_id
LEFT JOIN authors a ON ba.author_id = a.author_id
WHERE b.available_copies > 0
GROUP BY b.book_id;

-- عرض الاستعارات النشطة
CREATE VIEW ActiveBorrowings AS
SELECT 
    br.borrow_id,
    m.name AS member_name,
    m.email AS member_email,
    b.title AS book_title,
    br.borrow_date,
    br.due_date,
    DATEDIFF(br.due_date, CURDATE()) AS days_remaining
FROM borrowings br
JOIN members m ON br.member_id = m.member_id
JOIN books b ON br.book_id = b.book_id
WHERE br.status = 'borrowed';

-- عرض الكتب الأكثر استعارة
CREATE VIEW MostBorrowedBooks AS
SELECT 
    b.book_id,
    b.title,
    COUNT(br.borrow_id) AS borrow_count,
    GROUP_CONCAT(DISTINCT a.name SEPARATOR '، ') AS authors
FROM books b
LEFT JOIN borrowings br ON b.book_id = br.book_id
LEFT JOIN book_authors ba ON b.book_id = ba.book_id
LEFT JOIN authors a ON ba.author_id = a.author_id
GROUP BY b.book_id, b.title
ORDER BY borrow_count DESC;

-- عرض الأعضاء النشطين
CREATE VIEW ActiveMembers AS
SELECT 
    m.member_id,
    m.name,
    m.email,
    m.membership_date,
    COUNT(br.borrow_id) AS total_borrowings,
    SUM(CASE WHEN br.status = 'borrowed' THEN 1 ELSE 0 END) AS active_borrowings
FROM members m
LEFT JOIN borrowings br ON m.member_id = br.member_id
WHERE m.status = 'active'
GROUP BY m.member_id, m.name, m.email, m.membership_date;

-- =============================================
-- TEST QUERIES
-- =============================================

-- اختبار الـ Procedures
CALL AddBorrowing(3, 3, 14);
CALL ReturnBook(1);
CALL SearchBooks('تاريخ');

-- اختبار الـ Views
SELECT * FROM AvailableBooks;
SELECT * FROM ActiveBorrowings;
SELECT * FROM MostBorrowedBooks;
SELECT * FROM ActiveMembers;