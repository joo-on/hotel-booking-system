# Hotel Booking System

A high-concurrency hotel booking platform designed to handle **inventory consistency, payment flows, promotions, membership services, and event-driven integrations**.  
Inspired by real-world OTA systems (e.g., Yanolja), this project demonstrates how to manage bookings at scale.

## ✨ Features
- **Inventory Management**  
  - Prevent overbooking with row-level locking & optimistic concurrency control  
  - Support room-level inventory and multi-night surcharge pricing  

- **Booking & Payment**  
  - End-to-end booking flow with transactional integrity  
  - Integration with a mock payment gateway (reserve, commit, refund)  
  - Booking events published to Kafka for downstream services  

- **Review Service**  
  - Hotel-specific reviews with ratings and comments  
  - Stored in MongoDB for flexible schema and fast retrieval  
  - Integrated with search to filter hotels by rating  

- **Coupon & Promotion System**  
  - First-come-first-serve coupons with high concurrency handling  
  - Promotional campaigns with time/quantity limits  
  - Coupon usage/expiration events sent to Kafka  

- **Membership Service**  
  - Membership products with tier-based discounts and perks  
  - Points/benefits updated asynchronously via Kafka events  

- **Search & Filtering**  
  - Search hotels by **city, date, price, and amenities**  
  - **Location-based search**: find hotels near the user’s location or a specific point of interest  
  - Pagination and indexing for scalability  

- **Event-Driven Architecture (with Kafka)**  
  - Booking → Payment → Membership → Notification decoupled via Kafka topics  
  - Enables scalable, loosely coupled microservices  

## 🛠 Tech Stack
- Java 25 (LTS), Spring Boot 3, Spring Data JPA  
- MySQL, Redis  
- MongoDB (hotel reviews, logs)  
- Apache Kafka (event streaming)  
- Docker, Testcontainers  
- JUnit 5, RestAssured  

## 📚 What I Learned
- Designing **CQRS & Event Sourcing** for booking flows  
- Handling **concurrency & transactional consistency** under high load  
- Applying **Kafka for asynchronous communication** between services  
- Balancing business features (pricing, coupons, membership) with system reliability  
