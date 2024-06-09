#[allow(unused_imports)]
#[allow(dead_code)]
use std::collections::{HashMap, VecDeque};
use std::io::{self, Write};
use std::os::unix::fs::PermissionsExt;

#[allow(dead_code)]
#[derive(Debug, Default, Clone)]
struct Environment {
    vars: HashMap<String, String>,
    path: Vec<String>,
    history_enable: bool,
    history_file: String,
}

impl Environment {
    pub fn parse_var(&mut self, var: &str) { 
        let mut var: Vec<String> = var.split('=')
            .map(|v| v.to_string())
            .collect(); 

        var[1] = var[1].replace('"', "");
        
        match var[0].as_str() {
            "PATH" => self.parse_path(var[1].clone()),
            _ => todo!(),
        }
    }

    pub fn parse_path(&mut self, path: String) {
        self.path = path.split(':')
            .map(|path| path.to_string())
            .collect()
    }
}

#[allow(dead_code)]
#[derive(Debug)]
struct Command {
    builtin: Builtins,
    cmd: String,
    args: Vec<String>,
    flags: Option<Vec<Flag>>,
    env: Environment,
}

impl Command {
    pub fn new(mut input: String, environment: Environment) -> Command {
        if input.ends_with('\n') {
            input.pop();
        }

        let mut argv: VecDeque<&str> = input.split(' ').collect();
        let mut env = environment; 

        if argv[0] == " " {
            env.history_enable = false;
            argv.pop_front();
        }

        loop {
            match argv[0] {
                a if a.contains('=') => {        
                    env.parse_var(argv[0])
                },
                _ => break,
            }
            argv.pop_front();
        }

        let builtin = Builtins::from(argv[0]);
        let cmd = argv[0].to_string();
        argv.pop_front();

        let args = argv.iter()
            .map(|arg| arg.to_string())
            .collect();

        Command {
            builtin,
            cmd,
            args,
            flags: None,
            env,
        }
    }
}

#[allow(dead_code)]
#[derive(Debug)]
struct Flag {
    option: String,
    value: Option<String>,
}

#[derive(Debug, PartialEq)]
enum Builtins {
    Echo,
    Exit,
    Type,
    NotBuiltin,
}

impl From<&str> for Builtins {
    fn from(cmd: &str) -> Builtins {
        match cmd {
            "exit" => Builtins::Exit,
            "echo" => Builtins::Echo,
            "type" => Builtins::Type,
            _ => Builtins::NotBuiltin,
        }
    }
}

fn handle_cmd(environment: Environment) {
    print!("$ ");
    io::stdout().flush().unwrap();

    // Wait for user input
    let stdin = io::stdin();
    let mut input = String::new();
    stdin.read_line(&mut input).unwrap();
    let command = Command::new(input, environment);
    // println!("{:?}", command);

    match command.builtin {
        Builtins::Echo => builtin_echo(command),
        Builtins::Exit => builtin_exit(command),
        Builtins::Type => builtin_type(command),
        Builtins::NotBuiltin => println!("{}: command not found", command.cmd),
    }

    io::stdout().flush().unwrap();
}

fn builtin_exit(command: Command) {
    let code = command.args[0].parse::<i32>().unwrap();
    std::process::exit(code)
}

fn builtin_echo(command: Command) {
    println!("{}", command.args.join(" "))
}

fn builtin_type(command: Command) {
    let lookup_cmd = &command.args[0];

    if Builtins::from(lookup_cmd.as_str()) != Builtins::NotBuiltin {
        println!("{} is a shell builtin", lookup_cmd);
        return;
    }

    for path in command.env.path {
        let path = format!("{}/{}", path, lookup_cmd);

        if let Ok(file) = std::fs::metadata(path.as_str()) {
            let is_executable = file.permissions().mode() & 0o111 != 0;

            if file.is_file() && is_executable {
                println!("{} is {}", lookup_cmd, path);
                return;
            }
        }
    }

    println!("{} not found", lookup_cmd);
}

fn exec(command: Command) {
    todo!();
}

fn main() {
    let mut environment = Environment::default();
    environment.parse_path(std::env::var("PATH").unwrap());
        
    loop {
        handle_cmd(environment.clone());
    }
}
