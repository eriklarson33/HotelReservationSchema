-- Drop the database if it exists
DROP DATABASE IF EXISTS hotel_db;

-- Create a new database for the hotel SQL summative
CREATE DATABASE hotel_db;

-- Switch to the hotel_db database
USE hotel_db;

-- Create table for reservations
CREATE TABLE reservations (
	reservation_id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    client_contact INT UNSIGNED NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    paid TINYINT NOT NULL,
    base_amount DECIMAL(6,2) DEFAULT 0,
    addon_amount DECIMAL(6,2) DEFAULT 0,
    adjustment DECIMAL(6,2) DEFAULT 0,
    total_due DECIMAL(6,2) DEFAULT 0
    );

-- Create Client table
CREATE TABLE clients (
	client_id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(15) NOT NULL,
    last_name VARCHAR(20) NOT NULL,
    street_address VARCHAR(45) NOT NULL,
    city VARCHAR(30) NOT NULL,
    state CHAR(2) NOT NULL,
    zip_code INT NOT NULL,
    phone_number BIGINT UNSIGNED NOT NULL,
    email VARCHAR(30)
    );

-- Create a table to hold list of guests associated with each reservation
CREATE TABLE guests (
	guest_id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(15) NOT NULL,
    last_name VARCHAR(20) NOT NULL,
    age INT UNSIGNED NOT NULL,
    sex ENUM('MALE', 'FEMALE') NOT NULL,
    reservation_id INT UNSIGNED NOT NULL
    );
    
-- Create a table for each hotel room
CREATE TABLE hotel_rooms (
	room_id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    type_id INT UNSIGNED NOT NULL,
    area_sqft INT UNSIGNED NOT NULL,
    max_occupants INT UNSIGNED NOT NULL
    );
    
-- Create bridge table between the hotel_rooms table and reservations table
CREATE TABLE reservation_x_room (
	reservation_id INT UNSIGNED NOT NULL,
    room_id INT UNSIGNED NOT NULL
    );
    
-- Create table for amenities
CREATE TABLE amenities (
	amenity_id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    amenity_type VARCHAR(15) NOT NULL,
    amenity_description VARCHAR(50)
    );

-- Create table for add_ons
CREATE TABLE add_ons (
	add_on_id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    add_on_type VARCHAR(15) NOT NULL,
    add_on_price DECIMAL(6,2)
    );   
   
-- Create a bridge table between hotel_rooms table and amenities table
CREATE TABLE hotel_room_x_amenity (
	room_id INT UNSIGNED NOT NULL,
    amenity_id INT UNSIGNED NOT NULL
    );

-- Create a bridge table between add_ons table and reservations table
CREATE TABLE reservation_x_add_ons (
	reservation_id INT UNSIGNED NOT NULL,
    add_on_id INT UNSIGNED NOT NULL
    );
    
-- Create table for room types
CREATE TABLE room_types (
	type_id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    room_type_name VARCHAR(30) NOT NULL,
    type_base_rate DECIMAL(6,2) NOT NULL
    );
    
-- Create table for events and pricing
CREATE TABLE events_promotions (
	event_id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    event_name VARCHAR(30) NOT NULL,
    event_description VARCHAR(45),
    event_start_date DATE NOT NULL,
    event_end_date DATE NOT NULL,
    event_price_adjustment DECIMAL(6,2)
    );
    
-- Create a bridge table between reservations table and hotel_events table
CREATE TABLE reservations_x_eventspromo (
	reservation_id INT UNSIGNED,
    event_id INT UNSIGNED
    );
    
-- Create foreign keys for reservations table
ALTER TABLE reservations
	ADD CONSTRAINT client_contact_fk FOREIGN KEY (client_contact)
    REFERENCES clients (client_id) ON DELETE CASCADE;
    
-- Create foreign keys for guests table
ALTER TABLE guests
	ADD CONSTRAINT reservation_id_fk FOREIGN KEY (reservation_id)
    REFERENCES reservations (reservation_id) ON DELETE CASCADE;
    
-- Create foreign keys for hotel_rooms table
ALTER TABLE hotel_rooms
	ADD CONSTRAINT type_id_fk FOREIGN KEY (type_id)
    REFERENCES room_types (type_id) ON DELETE CASCADE;
    
-- Create foreign keys for hotel_room_x_amenity bridge table
ALTER TABLE hotel_room_x_amenity
	ADD CONSTRAINT room_id_fk FOREIGN KEY (room_id)
    REFERENCES hotel_rooms (room_id) ON DELETE CASCADE,
    ADD CONSTRAINT amenity_id_fk FOREIGN KEY (amenity_id)
    REFERENCES amenities (amenity_id) ON DELETE CASCADE;
    
-- Create foreign keys for reservation_x_add_ons bridge table
ALTER TABLE reservation_x_add_ons 
	ADD CONSTRAINT reservation_for_addOn_fk FOREIGN KEY (reservation_id)
    REFERENCES reservations (reservation_id) ON DELETE CASCADE,
    ADD CONSTRAINT addOns_per_reservation_fk FOREIGN KEY (add_on_id)
    REFERENCES add_ons (add_on_id) ON DELETE CASCADE;
    
-- Create foreign keys for reservation_x_room bridge table
ALTER TABLE reservation_x_room
	ADD CONSTRAINT res_room_id_fk FOREIGN KEY (room_id)
    REFERENCES hotel_rooms (room_id) ON DELETE CASCADE,
    ADD CONSTRAINT room_reservation_id_fk FOREIGN KEY (reservation_id)
    REFERENCES reservations (reservation_id) ON DELETE CASCADE;
    
-- Create foreign keys for reservation_x_events bridge table
ALTER TABLE reservations_x_eventspromo
	ADD CONSTRAINT reserv_for_event_id_fk FOREIGN KEY (reservation_id)
    REFERENCES reservations (reservation_id) ON DELETE CASCADE,
    ADD CONSTRAINT event_for_reserv_id_fk FOREIGN KEY (event_id)
    REFERENCES events_promotions (event_id) ON DELETE CASCADE;
    

    

-- CREATE VIEWS FOR QUICK ACCESS:

-- find a list of rooms and cost based on reservation_id, where the reservation_id is = 1
CREATE OR REPLACE VIEW list_of_rooms_by_reservation AS
select rs.reservation_id, cl.first_name, cl.last_name, rt.type_id, rt.room_type_name, rt.type_base_rate
FROM room_types rt
	INNER JOIN hotel_rooms hr ON
    rt.type_id = hr.type_id
    INNER JOIN reservation_x_room rx ON
    hr.room_id = rx.room_id
    INNER JOIN reservations rs ON
    rs.reservation_id = rx.reservation_id
    INNER JOIN clients cl ON
    cl.client_id = rs.reservation_id;
-- WHERE rs.reservation_id = 1;

-- find a list of add ons based on reservation_id, where the reservation_id is = 1
CREATE OR REPLACE VIEW addons_byReservation AS
select rs.reservation_id, first_name, cl.last_name, ao.add_on_type, ao.add_on_price
FROM add_ons ao
	INNER JOIN reservation_x_add_ons ax ON
    ao.add_on_id = ax.add_on_id
    INNER JOIN reservations rs ON
    ax.reservation_id = rs.reservation_id
    INNER JOIN clients cl ON
    rs.client_contact = cl.client_id
ORDER BY rs.reservation_id;
-- WHERE rs.reservation_id = 1;

-- find a list of events / promotions during a reservation, where the reservation_id is = 1
CREATE OR REPLACE VIEW eventsPromo_byReservation AS
select rs.reservation_id, cl.first_name, cl.last_name, rs.start_date, rs.end_date, ep.event_name, ep.event_start_date, ep.event_end_date, ep.event_price_adjustment
FROM events_promotions ep
	INNER JOIN reservations_x_eventspromo rxp ON
    ep.event_id = rxp.event_id
    INNER JOIN reservations rs ON
    rxp.reservation_id = rs.reservation_id
    INNER JOIN clients cl ON
    rs.client_contact = cl.client_id
WHERE (ep.event_start_date <= rs.end_date AND ep.event_end_date >= rs.start_date)
ORDER BY rs.reservation_id;


-- INSERT DATA FOR TABLE QUERIES

-- Insert values for the clients table
INSERT INTO clients (first_name, last_name, street_address, city, state, zip_code, phone_number, email)
VALUES ('Erik', 'Larson', '2908 W. 60th St.', 'Minneapolis', 'MN', 55410, 6127477158, 'eriklarson33@msn.com'),
('Kristi', 'Larson', '1734 Hidden Oak Trail', 'Mansfield', 'OH', 41906, 2419884567, 'kristilarson@larson.com'),
('Etor', 'Adamaley', '1600 W. Minstrel Blvd', 'Winnetonka', 'MN', 55419, 7896541238, 'etoradamaley@adameley.com');

-- Insert values for the reservations table
INSERT INTO reservations 
VALUES (default, 1, '2018-05-01', '2018-05-15', '0', default, default, default, default),
(default, 2, '2018-05-05', '2018-05-13', '0', default, default, default, default);

-- Insert values for room_types
INSERT INTO room_types
VALUES (default, 'single bed', 50.00),
(default, 'queen bed', 65.00),
(default, 'king bed', 75.00),
(default, 'two singles', 90.00),
(default, 'suite', 100.00);

-- Insert values for hotel_rooms table
INSERT INTO hotel_rooms
VALUES (default, 1, 400, 2),
(default, 1, 400, 2),
(default, 2, 500, 3),
(default, 3, 500, 3),
(default, 4, 600, 4),
(default, 5, 600, 4);



-- Insert values for add_ons
INSERT INTO add_ons
VALUES (default, 'HBO sub', 7.50),
(default, 'movie rental', 5.00),
(default, 'room service', 10.00);

-- Insert values for reservation_x_add_ons table
INSERT INTO reservation_x_add_ons
VALUES(1, 1),
(2,1),
(1, 2),
(1, 3);

-- Insert values for events_promotions table
INSERT INTO events_promotions
VALUES (default, 'Frequent Guest Promo', 'Discounts for premier members', '2018-01-01', '2018-12-31', -15.00),
(default, 'Wedding', 'special for large wedding reservations', '2018-04-01', '2018-06-15', -10.00),
(default, 'December Holidays', 'Surcharge for holiday traffic', '2017-12-01', '2018-01-05', 15.00);

-- Insert values for reservation_x_room
INSERT INTO reservation_x_room
VALUES (1, 1),
(1, 2),
(1, 4),
(2, 3);

-- Insert values for reservations_x_eventspromo
INSERT INTO reservations_x_eventspromo
VALUES (1, 1),
(1, 2),
(2, 1),
(2, 3);


-- Set the sum of the room_type table's type_base_rate to equal the reservations table's column base_amount
update reservations rs, 
(select sum(rt.type_base_rate) as rate_amount
	FROM room_types rt
	INNER JOIN hotel_rooms hr ON
    rt.type_id = hr.type_id
    INNER JOIN reservation_x_room rx ON
    hr.room_id = rx.room_id
    INNER JOIN reservations rs ON
    rs.reservation_id = rx.reservation_id
    INNER JOIN clients cl ON
    cl.client_id = rs.reservation_id WHERE rs.reservation_id = 1) as ru
    set rs.base_amount = ru.rate_amount where rs.reservation_id = 1;


-- Get the sum of all add ons where reservatino_id is equal to 1
update reservations rs,
(select sum(ao.add_on_price) as total_addons
FROM add_ons ao
	INNER JOIN reservation_x_add_ons ax ON
    ao.add_on_id = ax.add_on_id
    INNER JOIN reservations rs ON
    ax.reservation_id = rs.reservation_id
WHERE rs.reservation_id = 1) as rt
SET rs.addon_amount = rt.total_addons where rs.reservation_id = 1;

-- Get the sum of all events/promos where reservatino_id is equal to 1 for reservations.adjustment
update reservations rs,
(select sum(ep.event_price_adjustment) as total_adjustment
FROM events_promotions ep
	INNER JOIN reservations_x_eventspromo rxp ON
    ep.event_id = rxp.event_id
    INNER JOIN reservations rs ON
    rxp.reservation_id = rs.reservation_id
WHERE rs.reservation_id = rxp.reservation_id AND rxp.event_id = ep.event_id) as rt
SET rs.adjustment = rt.total_adjustment where rs.reservation_id = 1;

-- get TOTAL SUM billing information
UPDATE reservations
SET total_due = (SELECT SUM(base_amount+addon_amount+adjustment))
WHERE reservation_id = 1;
    