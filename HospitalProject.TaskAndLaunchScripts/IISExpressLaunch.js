const { env, argv } = require('process');
const fs = require('fs');
const { spawn } = require('child_process');

const args = argv.slice(2);

let IISExpressExecutablePath = "C:\\Program Files\\IIS Express\\iisexpress.exe";
let spawnIISExpressExec = null;
let IISExpressSiteName = null;
let IISExpressConfigPath = null;
let IISExpressPortNum = null;
let IISExpressIsStopping = false;
let IISExpressHasStopped = false;

const cleanUp = () => {
    if (spawnIISExpressExec && !spawnIISExpressExec.killed && !IISExpressIsStopping && !IISExpressHasStopped)
    {
        console.log(`Sending quit command to IIS Express (PID: ${spawnIISExpressExec.pid})`);
        spawnIISExpressExec.stdin.write('Q\n');
    }

    setTimeout(() => {
        if (spawnIISExpressExec && !spawnIISExpressExec.killed && IISExpressIsStopping && !IISExpressHasStopped)
        {
            console.log(`Force killing IIS Express (PID: ${spawnIISExpressExec.pid})`);
            spawnIISExpressExec.kill();
        }
    }, 3000);
};

process.on('SIGINT', cleanUp);   
process.on('SIGTERM', cleanUp); 
process.on('exit', cleanUp); 

for (let i = 0; i < args.length; i++)
{
    if (args[i] === '--sitename' || args[i] === '-s')
    {
        IISExpressSiteName = args[i + 1];
        i++;
    }
    else if (args[i] === '--configfile' || args[i] === '-c')
    {
        IISExpressConfigPath = args[i + 1];
        i++;            
    }
    else if (args[i] == '--iisexpressexecpath' || args[i] === '-i')
    {
        IISExpressExecutablePath = args[i];
        i++;
    }
}

try {
    IISExpressSiteName = IISExpressSiteName || env.IISEXPRESS_SITENAME || undefined;
    IISExpressConfigPath = IISExpressConfigPath || env.IISEXPRESS_CONFIG_PATH || undefined;

    if (IISExpressSiteName === undefined || IISExpressSiteName === null)
    {
        throw new "IIS Express Site Name was not provided";
    }

    if (!fs.existsSync(IISExpressConfigPath))
    {
        throw new "IIS Express Config not found";
    }

    if (!fs.existsSync(IISExpressExecutablePath))
    {
        throw new "IIS Express executable not found";
    }

    const args = [`/site:${IISExpressSiteName}`, `/config:${IISExpressConfigPath}`];
    spawnIISExpressExec = spawn(IISExpressExecutablePath, args);

    spawnIISExpressExec.stdout.on('data', (data) => {
        const stdOutData = data.toString().trimEnd();
        console.log(stdOutData);

        if (stdOutData.includes('Successfully registered URL ')) {
            IISExpressPortNum = stdOutData.match("^Successfully registered URL \"(?:http|https):\/\/[a-zA-Z0-9\.]+:([0-9]+)\/\" for site \".+\" application \".+\"$")[1];
        }

        if (stdOutData.includes('Stopping IIS Express ...')) {
            IISExpressIsStopping = true;
        }
        
        if (stdOutData.includes('IIS Express stopped.')) {
            IISExpressHasStopped = true;
        }

        if (stdOutData.includes('IIS Express is running.'))
        {
            console.log(`IIS running on port ${IISExpressPortNum}`);
        }
    });

    spawnIISExpressExec.stderr.on('data', (data) => {
        console.error(data.toString().trimEnd());
    });


} catch (error) {
    console.error(error);
    process.exit(1);
}
finally
{
    spawnIISExpressExec.on('close', (code) => {
        if (IISExpressIsStopping && IISExpressHasStopped)
        {
            console.log(`child process exited with code ${code}`);
        }

        if (code !== 0 && (!IISExpressIsStopping || !IISExpressHasStopped))
        {
            console.error(`IIS Express exited unexpectedly with code ${code}`);        
        }
    });
}