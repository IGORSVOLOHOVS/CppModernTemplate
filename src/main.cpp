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