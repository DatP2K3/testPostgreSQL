CREATE DATABASE evotek;
/*
- Tạo bảng departments
- Áp dụng SERIAL
*/
CREATE TABLE departments (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    head_of_department VARCHAR(50) NOT NULL
);

/*
- Tạo bảng employees
- Áp dụng UNIQUE để đảm bảo giá trị của telephone và email là duy nhất
- Áp dụng DEFAULT để cài đặt giá trị mặc định cho total_day_offs = 0
- Áp dụng CONSTRAINT để cài đặt khoá chính và khoá ngoại
*/
CREATE TABLE employees (
	id SERIAL,
	name VARCHAR(50) NOT NULL,
	age INT NOT NULL,
	email VARCHAR(150) UNIQUE NOT NULL,
	telephone VARCHAR(11) UNIQUE NOT NULL,
	address VARCHAR(255),
	total_day_offs INT DEFAULT 0,
	salary INT NOT NULL,
	department_id INT,
	CONSTRAINT pk_employees PRIMARY KEY (id),
	CONSTRAINT fk_employees_department FOREIGN KEY (department_id) REFERENCES departments(id)
);

-- Tạo Index cho cột email của bảng e_id ON orders(customer_id);
CREATE INDEX idx_email ON employees(email);

-- Tạo bảng day_offs
CREATE TABLE day_offs (
	id SERIAL,
	start_day DATE NOT NULL,
	end_day DATE NOT NULL,
	employee_id INT,
	CONSTRAINT fk_day_offs_employees FOREIGN KEY (employee_id) REFERENCES employees(id),
	CONSTRAINT pk_day_offs PRIMARY KEY (start_day, id)
) PARTITION BY RANGE (start_day);

-- Tạo các PARTITION theo năm 
CREATE TABLE day_off_2023 PARTITION OF day_offs
    FOR VALUES FROM ('2023-01-01') TO ('2023-12-31');

CREATE TABLE day_off_2024 PARTITION OF day_offs
    FOR VALUES FROM ('2024-01-01') TO ('2024-12-31');

-- Tạo các SUB PARTITION theo tháng
CREATE TABLE day_off_2023_q1 PARTITION OF day_off_2023
    FOR VALUES FROM ('2023-01-01') TO ('2023-01-31');

CREATE TABLE day_off_2023_q2 PARTITION OF day_off_2023
    FOR VALUES FROM ('2023-04-01') TO ('2023-06-30');

CREATE TABLE day_off_2023_q3 PARTITION OF day_off_2023
    FOR VALUES FROM ('2023-07-01') TO ('2023-09-30');

CREATE TABLE day_off_2023_q4 PARTITION OF day_off_2023
    FOR VALUES FROM ('2023-10-01') TO ('2023-12-31');

--Tạo view employee_department kết hợp dữ liệu từ bảng employees và departments
CREATE VIEW employee_department AS
SELECT e.name AS employee_name, e.salary AS employee_salary, d.name AS department_name
FROM employees e
JOIN departments d ON e.department_id = d.id;

-- Tạo thủ tục cập nhật lương nhân viên
CREATE PROCEDURE update_employee_salary(IN emp_id INT, IN new_salary INT)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE employees
    SET salary = new_salary
    WHERE id = emp_id;
END;
$$;

-- Tạo hàm trả về lương nhân viên
CREATE FUNCTION get_employee_salary(employee_id INT) 
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    salary INT;
BEGIN
    SELECT salary INTO salary
    FROM employees
    WHERE id = employee_id;
    RETURN salary - total_day_offs * salary / 30;
END;
$$;

-- Tạo hàm trigger cập nhật total_day_offs của bảng employees
CREATE OR REPLACE FUNCTION update_total_days_off()
RETURNS TRIGGER AS $$
DECLARE
    days_off INT;
BEGIN
    days_off := (NEW.end_day - NEW.start_day + 1);
	
    UPDATE employees
    SET total_day_offs = total_day_offs + days_off
    WHERE id = NEW.employee_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Tạo TRIGGER kích hoạt khi chèn thêm dữ liệu vào bảng day_offs
CREATE TRIGGER after_day_offs_insert
AFTER INSERT ON day_offs
FOR EACH ROW
EXECUTE FUNCTION update_total_days_off();

-- Thêm các bản ghi vào bảng departments
INSERT INTO departments (name, head_of_department) 
VALUES 
('Marketing', 'Nguyễn Thị Hạnh'),
('HR', 'Vũ Thị Lụa'),
('IT', 'Trần Văn Định');

-- Lấy ra các bản ghi của bảng departments
SELECT * FROM departments;

-- Thêm các bản ghi vào bảng employees
INSERT INTO employees (name, age, email, telephone, address, salary, department_id) 
VALUES 
('Đỗ Thị Thanh Thảo', 22, 'thanhthao@gmail.com', '0987364182', 'Hà Nam', 15000000, 1),
('Phan Thị Ngọc Ánh', 20, 'anhduong@gmail.com', '0872635482', 'Hải Phòng', 18000000, 2),
('Phan Đình Đạt', 21, 'datp2k3@gmail.com', '0862269885', 'Hà Nội', 14000000, 3);

-- Lấy ra các bản ghi của bảng employees
SELECT * FROM employees;

-- Thêm các bản ghi vào bảng day_offs
INSERT INTO day_offs (start_day, end_day, employee_id) 
VALUES 
('2023-01-01', '2023-01-05', 1),
('2023-03-10', '2023-03-12', 2),
('2023-07-20', '2023-07-25', 3);

-- Lấy ra các bản ghi của bảng day_offs
SELECT * FROM day_offs;

--Lấy ra các bản ghi từ view employee_department
SELECT * FROM employee_department;

-- Dùng Transaction
BEGIN;
UPDATE employees SET salary = salary - 100 WHERE id = 1;
UPDATE departments SET head_of_department = 'Phạm Như Công' WHERE id = 2;
COMMIT;
--ROLLBACK;
SELECT * FROM employees;
SELECT * FROM departments;