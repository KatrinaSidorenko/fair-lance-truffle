const JobFactory = artifacts.require("JobFactory");
const JobEscrow = artifacts.require("JobEscrow");

contract("Freelance Marketplace Workflow", (accounts) => {
  const [client, freelancer] = accounts;
  let factory, jobAddress, job;

  before(async () => {
    factory = await JobFactory.deployed();
  });

  it("Client creates a job with deposit", async () => {
    const tx = await factory.createJob("job-001", {
      from: client,
      value: web3.utils.toWei("1", "ether")
    });

    // Parse JobCreated event
    jobAddress = tx.logs[0].args.jobAddress;
    console.log("✅ Job created at:", jobAddress);

    // Attach Escrow contract
    job = await JobEscrow.at(jobAddress);

    const contractBalance = await web3.eth.getBalance(jobAddress);
    console.log("💰 Escrow contract balance:", web3.utils.fromWei(contractBalance, "ether"), "ETH");
  });

  it("Client assigns freelancer", async () => {
    await job.assignFreelancer(freelancer, { from: client });
    const assignedFreelancer = await job.freelancer();
    console.log("👷 Freelancer assigned:", assignedFreelancer);
  });

  it("Freelancer submits work", async () => {
    await job.submitWork("submission-001", { from: freelancer });
    const submissionId = await job.submissionId();
    console.log("📩 Work submitted with ID:", submissionId);
  });

  it("Client approves work and releases funds", async () => {
    const beforeBalance = web3.utils.toBN(await web3.eth.getBalance(freelancer));
    await job.approveWork({ from: client });
    const afterBalance = web3.utils.toBN(await web3.eth.getBalance(freelancer));

    console.log("✅ Work approved");
    console.log("💸 Freelancer balance change:", web3.utils.fromWei(afterBalance.sub(beforeBalance), "ether"), "ETH");
  });
});
