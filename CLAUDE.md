# Hotel Booking System - AI Assistant Context

## Project Overview

This is a **hand-made** hotel booking system built to demonstrate production-level coding skills and microservices architecture understanding. Every line of code is written manually with full comprehension of the underlying concepts.

## Project Goals

- 🎯 **Demonstrate coding proficiency**: Showcase ability to build complex systems from scratch
- 📚 **Deep learning**: Understand every component, pattern, and architectural decision
- 🏗️ **Production quality**: Write maintainable, scalable, and well-tested code
- 🔧 **Modern practices**: Apply industry best practices and design patterns

## Technology Stack

- **Backend**: Java 25, Spring Boot 4, Spring Cloud
- **Architecture**: Microservices (Property, Inventory, Booking, Review, Coupon, Membership, Search services)
- **Database**: MySQL 8.0+ (SPATIAL INDEX, JSON, CHECK constraints), Redis, MongoDB
- **Message Queue**: Apache Kafka
- **Infrastructure**: Docker, Docker Compose, Testcontainers
- **Build Tool**: Gradle (multi-project setup)

## AI Usage Philosophy

Claude is used as a **technical reviewer and learning accelerator**, not a code generator.

**How I use it:**
- Code review and architectural validation after implementation
- Identifying security vulnerabilities and edge cases
- Staying current with Java 25 and Spring Boot 4 features
- Exploring alternative approaches and trade-offs

All code is written and understood by me. AI assists with review and knowledge discovery.

## Project Structure

```
hotel-booking-system/
├── services/
│   ├── property-service/      # Hotel metadata with version control & i18n
│   ├── inventory-service/     # ARI (Availability, Rate, Inventory) management
│   ├── booking-service/       # Booking & payment flows
│   ├── review-service/        # Hotel reviews (MongoDB)
│   ├── coupon-service/        # Promotions & coupon management
│   ├── membership-service/    # Membership tiers & benefits
│   └── search-service/        # Search & filtering with location-based queries
├── infrastructure/
│   └── docker-compose.yml     # MySQL, Redis, MongoDB, Kafka
└── docs/
    └── schema/                # Database schemas and ERDs
```

## Development Workflow

1. **Design**: Plan the feature and database schema
2. **Implement**: Write code manually with full understanding
3. **Review**: Use Claude to review and suggest improvements
4. **Refine**: Apply feedback and improve code quality
5. **Document**: Record technical decisions when needed
6. **Commit**: Clear, descriptive commit messages

## Code Quality Standards

### Code Style
- **Spring Java Format** (120 characters, 4-space indentation)
- Automated formatting via Gradle plugin
- Use Lombok judiciously:
  - ✅ `@Builder`, `@Value`, `@Getter`, `@RequiredArgsConstructor`, `@Slf4j`
  - ❌ `@Data` (too magical, use specific annotations instead)

**Gradle Commands:**
```bash
# Check if code is formatted correctly
./gradlew checkFormat

# Auto-format all code
./gradlew format
```

### Architecture
- Decided per service based on domain complexity
- Documented after implementation in each service's README

### Testing
- **No specific coverage targets** - test what matters
- **Unit Tests**: Domain objects and business logic
- **Integration Tests**: Service layer with real database (Testcontainers)
  - Test single service end-to-end (API → DB)
  - Mock external dependencies (Kafka, other services)
- **E2E Tests**: Critical user scenarios across multiple services
  - Full infrastructure running (all services + Kafka + DBs)
  - Limited to essential flows (booking, payment, etc.)
- **TDD Approach**: Applied selectively where it adds value
  - Use TDD for:
    - Complex business logic (pricing, inventory, concurrency)
    - Critical features requiring high confidence
    - Experimental learning of new patterns
  - Skip TDD for:
    - Simple CRUD operations (test after implementation)

### Documentation
- **JavaDoc**: Minimal - only for complex logic or public APIs
- **Inline Comments**: Prefer self-documenting code
  - Add comments only for "why", not "what"
  - Explain complex logic when code alone isn't clear
- **API Documentation**: Swagger/OpenAPI with annotations
  - Document controllers with `@Operation`, `@ApiResponse`
  - Document DTOs with `@Schema` annotations

## Commit Message Convention

Following [Chris Beams' guide](https://chris.beams.io/posts/git-commit/):

1. Separate subject from body with a blank line
2. Limit the subject line to 50 characters
3. Capitalize the subject line
4. Do not end the subject line with a period
5. Use the imperative mood in the subject line
6. Wrap the body at 72 characters
7. Use the body to explain what and why vs. how

**Examples:**
```
Add property creation endpoint

Implement POST /api/v1/properties endpoint with full validation.
Includes support for multi-language property names and descriptions.

Fix race condition in room availability check

Use pessimistic locking to prevent double-booking when multiple
users attempt to reserve the same room simultaneously.
```

## AI Assistant Guidelines

When reviewing code, focus on:
- Security vulnerabilities and edge cases
- Performance bottlenecks and scalability concerns
- Proper use of Spring Boot 4 and Java 25 features
- Alternative approaches with trade-off analysis
- Related advanced topics worth exploring

Ask probing questions about design decisions rather than just pointing out issues.
