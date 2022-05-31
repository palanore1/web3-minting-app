import WalletBalance from './WalletBalance';
import { useEffect, useState } from 'react';

import { ContractFactory, ethers } from 'ethers';
import CoolPunks from '../artifacts/contracts/CoolPunks.sol/CoolPunks.json';

const contractAddress = '0xB3DdF47431C8683f6F5B869eF91BF03308DA848a';

const provider = new ethers.providers.Web3Provider(window.ethereum);

// get the end user
const signer = provider.getSigner();

// get the smart contract
const contract = new ethers.Contract(contractAddress, CoolPunks.abi, signer);


function Home() {

  const [totalMinted, setTotalMinted] = useState(0);
  useEffect(() => {
    getCount();
  }, []);

  const getCount = async () => {
    const count = await contract.count();
    console.log(parseInt(count));
    setTotalMinted(parseInt(count));
  };

  return (
    <div>
      <WalletBalance />

      <h1>Cool Punks NFT Collection</h1>
      <div className="container">
        <div className="row">
          {Array(totalMinted + 1)
            .fill(0)
            .map((_, i) => (
              <div key={i} className="col-sm">
                <NFTImage tokenId={i} getCount={getCount} />
              </div>
            ))}
        </div>
      </div>
    </div>
  );
}

function NFTImage({ tokenId, getCount }) {
  const contentId = 'Qmciutf991sTocVdBykwTfajKcq3Ww5VbLTJLj7raZajNf';
  const imageId = 'QmPvUPaqy5LBQggKhUHNQE69LHmbFkFYbPxesXZrLxEiRd';
  const metadataURI = `https://gateway.pinata.cloud/ipfs/${contentId}/${tokenId}.json`;
  const imageURI = `https://gateway.pinata.cloud/ipfs/${imageId}/${tokenId}.jpeg`;
  //   const imageURI = `img/${tokenId}.png`;

  const [isMinted, setIsMinted] = useState(false);
  useEffect(() => {
    getMintedStatus();
  }, [isMinted]);

  const getMintedStatus = async () => {
    const result = await contract.isContentOwned(metadataURI);
    console.log(result);
    setIsMinted(result);
  };

  const [isStaked, setIsStaked] = useState(false);
  useEffect(() => {
    getStakedStatus();
  }, [isStaked]);

  const getStakedStatus = async () => {
    const result = await contract.isStaked(tokenId);
    console.log(result);
    setIsStaked(result);
  };

  const mintToken = async () => {
    const connection = contract.connect(signer);
    const result = await contract.createCollectible(0, metadataURI, {
      value: ethers.utils.parseEther('0.05'),
    });

    await result.wait();
    getMintedStatus();
    getCount();
  };

  async function getURI() {
    const uri = await contract.tokenURI(tokenId);
    alert(uri);
  }

  async function stakeToken() {
    const connection = contract.connect(signer);
    const result = await contract.stake(0, tokenId);
    await result.wait();
    alert("Token staked !");
  }

  async function unstakeToken() {
    const connection = contract.connect(signer);
    const result = await contract.unstake(0, tokenId, { value: ethers.utils.parseEther('0.01') });
    await result.wait();
    alert("Token unstaked !");
  }

  return (
    <div className="card" style={{ width: '18rem' }}>
      <img className="card-img-top" src={isMinted ? imageURI : 'img/placeholder.png'}></img>
      <div className="card-body">
        <h5 className="card-title">COOL PUNK #{tokenId}</h5>
        {!isMinted ? (
          <button className="btn btn-primary" onClick={mintToken}>
            Mint
          </button>
        ) : (
          <button className="btn btn-secondary" onClick={stakeToken}>
            Stake
          </button>
        )}
        <button className="btn btn-secondary" onClick={unstakeToken}>
          Unstake
        </button>
      </div>
    </div>
  );
}

export default Home;
