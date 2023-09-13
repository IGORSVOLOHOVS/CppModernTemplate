
It looks like you've provided code snippets for different topics, such as working with Boost, Google Benchmark, Google Test, SQLite database, and OpenGL. Below, I've organized and formatted the code snippets into separate sections for each topic. You can use this organized format as a starting point for your GitHub README.md or any other documentation you're preparing.

---

## Library Installation

To begin, make sure you have the required libraries installed. Here are the commands to install the necessary libraries on both Ubuntu and MinGW MSYS2:

```bash
# Ubuntu
sudo apt-get install libboost-all-dev
sudo apt-get install libgtest-dev
sudo apt-get install libsqlite3-dev
sudo apt-get install libbenchmark-dev
sudo apt-get install libglew-dev
sudo apt-get install libglfw3-dev

# MinGW MSYS2
pacman -S mingw-w64-x86_64-boost
pacman -S mingw-w64-x86_64-gtest
pacman -S mingw-w64-x86_64-sqlite3
pacman -S mingw-w64-x86_64-benchmark
pacman -S mingw-w64-x86_64-glew
pacman -S mingw-w64-x86_64-glfw
pacman -S mingw-w64-x86_64-opengl-man-pages
pacman -S mingw-w64-x86_64-qt5
```

---

## Math using Boost and Random Matrix

```cpp
#include <boost/numeric/ublas/matrix.hpp>
#include <boost/numeric/ublas/io.hpp>
#include <boost/math/quadrature/trapezoidal.hpp>
#include <iostream>
#include <random>  // для std::mt19937 и std::uniform_real_distribution

double f(double x) {
    return x*x;
}

int main() {
    using namespace boost::numeric::ublas;

    // Определение матрицы 3x3
    matrix<double> m(3, 3);
    m(0,0) = 1.0; m(0,1) = 2.0; m(0,2) = 3.0;
    m(1,0) = 4.0; m(1,1) = 5.0; m(1,2) = 6.0;
    m(2,0) = 7.0; m(2,1) = 8.0; m(2,2) = 9.0;

    std::cout << "Matrix:\n" << m << std::endl;

    double a = 0.0;
    double b = 2.0;

    double integral = boost::math::quadrature::trapezoidal(f, a, b);
    std::cout << "Integral of x^2 from " << a << " to " << b << " is: " << integral << std::endl;

     using namespace boost::numeric::ublas;

    matrix<double> m2(3, 3);

    std::mt19937 gen;  // Mersenne Twister 19937 генератор
    std::uniform_real_distribution<> dis(0.0, 1.0);  // равномерное распределение от 0 до 1

    for (unsigned i = 0; i < m.size1(); ++i) {
        for (unsigned j = 0; j < m.size2(); ++j) {
            m2(i,j) = dis(gen);
        }
    }

    std::cout << "Random matrix:\n" << m2 << std::endl;

    return 0;
}
```

---

## Google Benchmark

```cpp
#include <benchmark/benchmark.h>

// Не экспортируемые, внутренние функции
void internal_function_1() {
    static int i = 0;
    i++;
}

void internal_function_2() {
    static int y = 0;
    ++y;
}

// Экспортируемые функции тестирования
void benchmark_function_1(benchmark::State& state) {
    for (auto _ : state) {
        internal_function_1();
    }
}

void benchmark_function_2(benchmark::State& state) {
    for (auto _ : state) {
        internal_function_2();
    }
}

// Регистрируем функции для бенчмаркинга
BENCHMARK(benchmark_function_1);
BENCHMARK(benchmark_function_2);

// Запускаем бенчмарк
BENCHMARK_MAIN();
```

---

## Google Test

```cpp
#include <gtest/gtest.h>

bool test_function_1() {
    return true;
}

int test_function_2(int a, int b) {
    return a + b;
}

// Регистрируем функции для тестирования
TEST(test_function_1, test_function_1) {
    EXPECT_TRUE(test_function_1());
}

TEST(test_function_2, test_function_2) {
    EXPECT_EQ(test_function_2(1, 2), 3);
}



int main(int argc, char** argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
```

---

## Database using SQLite

```cpp
#include <iostream>
#include <sqlite3.h>

static int callback(void *data, int argc, char **argv, char **azColName) {
    std::cout << "Результат выборки:" << std::endl;
    for (int i = 0; i < argc; i++) {
        std::cout << azColName[i] << " = " << (argv[i] ? argv[i] : "NULL") << std::endl;
    }
    return 0;
}

int save() {
    sqlite3 *db;
    char *errMsg = 0;

    // Open or create a database
    int rc = sqlite3_open("database/example.db", &db);
    if (rc) {
        std::cerr << "Error opening/creating the database: " << sqlite3_errmsg(db) << std::endl;
        return 1;
    } else {
        std::cout << "Database opened/created successfully." << std::endl;
    }

    // Create a table if it doesn't exist
    const char *createTableQuery = "CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER);";
    rc = sqlite3_exec(db, createTableQuery, 0, 0, &errMsg);
    if (rc != SQLITE_OK) {
        std::cerr << "Error creating table: " << errMsg << std::endl;
        sqlite3_free(errMsg);
    } else {
        std::cout << "Table created successfully." << std::endl;
    }

    // Insert a record into the table
    const char *insertQuery = "INSERT INTO users (name, age) VALUES ('John', 25);";
    rc = sqlite3_exec(db, insertQuery, 0, 0, &errMsg);
    if (rc != SQLITE_OK) {
        std::cerr << "Error inserting record: " << errMsg << std::endl;
        sqlite3_free(errMsg);
    } else {
        std::cout << "Record inserted successfully." << std::endl;
    }

    // Select data from the table
    const char *selectQuery = "SELECT * FROM users;";
    rc = sqlite3_exec(db, selectQuery, callback, 0, &errMsg);
    if (rc != SQLITE_OK) {
        std::cerr << "Error selecting data: " << errMsg << std::endl;
        sqlite3_free(errMsg);
    }

    // Update data in the table
    const char *updateQuery = "UPDATE users SET age = 30 WHERE name = 'John';";
    rc = sqlite3_exec(db, updateQuery, 0, 0, &errMsg);
    if (rc != SQLITE_OK) {
        std::cerr << "Error updating data: " << errMsg << std::endl;
        sqlite3_free(errMsg);
    } else {
        std::cout << "Data updated successfully." << std::endl;
    }

    // Remove a record from the table
    const char *removeQuery = "DELETE FROM users WHERE name = 'John';";
    rc = sqlite3_exec(db, removeQuery, 0, 0, &errMsg);
    if (rc != SQLITE_OK) {
        std::cerr << "Error removing record: " << errMsg << std::endl;
        sqlite3_free(errMsg);
    } else {
        std::cout << "Record removed successfully." << std::endl;
    }

    // Close the database
    sqlite3_close(db);

    return 0;
}
```

---

## OpenGL

```cpp
#include <iostream>
#include <GL/glew.h>
#include <GLFW/glfw3.h>

int main() {
    // Инициализация GLFW
    if (!glfwInit()) {
        std::cerr << "Не удалось инициализировать GLFW!" << std::endl;
        return -1;
    }

    // Создание окна в режиме оконного режима и его контекста OpenGL
    GLFWwindow* window = glfwCreateWindow(640, 480, "Привет, OpenGL", nullptr, nullptr);
    if (!window) {
        std::cerr << "Не удалось создать окно GLFW!" << std::endl;
        glfwTerminate();
        return -1;
    }

    // Установка текущего контекста окна
    glfwMakeContextCurrent(window);

    // Инициализация GLEW
    if (glewInit() != GLEW_OK) {
        std::cerr << "Не удалось инициализировать GLEW!" << std::endl;
        return -1;
    }

    // Определение вершин треугольника
    float vertices[] = {
        0.0f,  0.5f,
       -0.5f, -0.5f,
        0.5f, -0.5f
    };

    // Создание буфера вершин и копирование данных вершин в него
    GLuint vbo;
    glGenBuffers(1, &vbo);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    // Использование шейдеров (Это простой шейдер пропускания для демонстрации)
    const char* vertexShaderSrc = R"glsl(
        #version 330 core
        layout(location = 0) in vec2 position;
        void main() {
            gl_Position = vec4(position, 0.0, 1.0);
        }
    )glsl";

    const char* fragmentShaderSrc = R"glsl(
        #version 330 core
        out vec4 color;
        void main() {
            color = vec4(1.0, 0.0, 0.0, 1.0);  // Красный цвет
        }
    )glsl";

    int success;
    char infoLog[512];

    // Вершинный шейдер
    GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertexShader, 1, &vertexShaderSrc, nullptr);
    glCompileShader(vertexShader);
    glGetShaderiv(vertexShader, GL_COMPILE_STATUS, &success);
    if (!success) {
        glGetShaderInfoLog(vertexShader, 512, nullptr, infoLog);
        std::cerr << "Ошибка компиляции вершинного шейдера\n" << infoLog << std::endl;
    }

    // Фрагментный шейдер
    GLuint fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragmentShader, 1, &fragmentShaderSrc, nullptr);
    glCompileShader(fragmentShader);
    glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, &success);
    if (!success) {
        glGetShaderInfoLog(fragmentShader, 512, nullptr, infoLog);
        std::cerr << "Ошибка компиляции фрагментного шейдера\n" << infoLog << std::endl;
    }

    // Связывание шейдеров для создания шейдерной программы
    GLuint shaderProgram = glCreateProgram();
    glAttachShader(shaderProgram, vertexShader);
    glAttachShader(shaderProgram, fragmentShader);
    glLinkProgram(shaderProgram);
    glGetProgramiv(shaderProgram, GL_LINK_STATUS, &success);
    if (!success) {
        glGetProgramInfoLog(shaderProgram, 512, nullptr, infoLog);
        std::cerr << "Ошибка связывания шейдерной программы\n" << infoLog << std::endl;
    }
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);

    // Цикл рендеринга
    while (!glfwWindowShouldClose(window)) {
        // Очистка экрана
        glClear(GL_COLOR_BUFFER_BIT);

        // Рисование треугольника
        glUseProgram(shaderProgram);
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(float), nullptr);
        glEnableVertexAttribArray(0);
        glDrawArrays(GL_TRIANGLES, 0, 3);

        // Переключение переднего и заднего буферов
        glfwSwapBuffers(window);

        // Обработка событий
        glfwPollEvents();
    }

    glfwTerminate();
    return 0;
}
```

---

