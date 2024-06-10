#[allow(unused_imports)]
#[allow(dead_code)]
use std::collections::{HashMap, VecDeque};
use std::{env, fs};
use std::io::{self, Write};
use std::path::Path;
use std::os::unix::fs::PermissionsExt;
use std::process::Command as rs_command;

#[allow(dead_code)]
#[derive(Debug, Default, Clone)]
struct Environment {
    vars: HashMap<String, String>,
    path: Vec<String>,
    home: String,
    history_enable: bool,
    history_file: String,
}

impl Environment {
    fn new() -> Environment {
        let mut e = Environment {
            home: env::var("HOME").unwrap(),
            ..Default::default()
        };

        e.parse_path(env::var("PATH").unwrap());
        e
    }

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
#[derive(Debug, Clone)]
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
#[derive(Debug, Clone)]
struct Flag {
    option: String,
    value: Option<String>,
}

#[derive(Debug, Clone, PartialEq)]
enum Builtins {
    Cd,
    Echo,
    Exit,
    Pwd,
    Type,
    NotBuiltin,
}

impl From<&str> for Builtins {
    fn from(cmd: &str) -> Builtins {
        match cmd {
            "cd"   => Builtins::Cd,
            "exit" => Builtins::Exit,
            "echo" => Builtins::Echo,
            "pwd"  => Builtins::Pwd,
            "type" => Builtins::Type,
            _ => Builtins::NotBuiltin,
        }
    }
}

fn handle_cmd(environment: Environment) {
    print!("$ ");
    io::stdout().flush().unwrap();

    let stdin = io::stdin();
    let mut input = String::new();
    stdin.read_line(&mut input).unwrap();
    let command = Command::new(input, environment.clone());
    // println!("{:?}", command);

    run(command);

    io::stdout().flush().unwrap();
}

#[allow(dead_code)]
fn handle_script(path: String, environment: Environment) {
    let script = fs::read_to_string(Path::new(&path)).unwrap();
    let command = Command::new(script, environment.clone());
    run(command);
}

fn run(command: Command) { 
    match command.builtin {
        Builtins::Cd   => cd(command),
        Builtins::Echo => builtin_echo(command),
        Builtins::Exit => builtin_exit(command),
        Builtins::Pwd  => builtin_pwd(),
        Builtins::Type => builtin_type(command),
        Builtins::NotBuiltin => {
            if let Some(path) = file_exists_and_executable(&command.cmd, &command) {
                exec(path, command.clone());
            } else {
                println!("{}: command not found", command.cmd)
            }
        }
    }
}

fn builtin_exit(command: Command) {
    let code = command.args[0].parse::<i32>().unwrap();
    std::process::exit(code)
}

fn builtin_echo(command: Command) {
    println!("{}", command.args.join(" "))
}

fn builtin_pwd() {
    println!("{}", env::current_dir().unwrap().display());
}

fn exec(path: String, command: Command) {
    let _ = rs_command::new(path)
        .args(command.args)
        .status();
}

fn cd(command: Command) {
    let path = match command.args[0].as_str() {
        "~" => Path::new(command.env.home.as_str()),
        _ => Path::new(command.args[0].as_str()),
    };

    if env::set_current_dir(path).is_err() {
        println!("{}: No such file or directory", path.display());
    }
}

fn file_exists_and_executable(lookup_cmd: &str, command: &Command) -> Option<String> {
    for path in &command.env.path {
        let path = format!("{}/{}", path, lookup_cmd);

        if let Ok(file) = fs::metadata(path.as_str()) {
            let is_executable = file.permissions().mode() & 0o111 != 0;

            if file.is_file() && is_executable {
                return Some(path);
            }
        }
    } 
    
    None
}

fn builtin_type(command: Command) {
    let lookup_cmd = &command.args[0];

    if Builtins::from(lookup_cmd.as_str()) != Builtins::NotBuiltin {
        println!("{} is a shell builtin", lookup_cmd);
        return;
    }

    if let Some(path) = file_exists_and_executable(lookup_cmd, &command) { 
        println!("{} is {}", lookup_cmd, path);
    } else {
        println!("{} not found", lookup_cmd);
    }
}

fn main() {
    loop {
        handle_cmd(Environment::new());
    }
}
